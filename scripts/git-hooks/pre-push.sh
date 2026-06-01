#!/usr/bin/env sh

set -eu

zero_sha="0000000000000000000000000000000000000000"
should_run_lint=0
should_run_full_lint=0
changed_files_tmp="$(mktemp)"
lint_tasks_tmp="$(mktemp)"

cleanup() {
  rm -f "$changed_files_tmp" "$lint_tasks_tmp"
}

trap cleanup EXIT

add_lint_task() {
  task="$1"
  if [ -n "$task" ]; then
    printf "%s\n" "$task" >> "$lint_tasks_tmp"
  fi
}

resolve_base_ref() {
  origin_head_ref="$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -n "$origin_head_ref" ]; then
    printf "%s\n" "$origin_head_ref"
    return
  fi

  if git show-ref --verify --quiet refs/remotes/origin/main; then
    printf "%s\n" "refs/remotes/origin/main"
    return
  fi

  if git show-ref --verify --quiet refs/remotes/origin/master; then
    printf "%s\n" "refs/remotes/origin/master"
    return
  fi

  printf "%s\n" ""
}

collect_changed_files_from_base() {
  local_sha="$1"
  base_ref="$2"
  if [ -z "$base_ref" ]; then
    return 1
  fi

  base_sha="$(git merge-base "$local_sha" "$base_ref" 2>/dev/null || true)"
  if [ -z "$base_sha" ]; then
    return 1
  fi

  git diff --name-only "$base_sha..$local_sha" >> "$changed_files_tmp"
}

while read -r local_ref local_sha remote_ref remote_sha; do
  [ -z "$local_ref" ] && continue

  case "$remote_ref" in
    refs/heads/main|refs/heads/master)
      echo "[Policy] main/master로 직접 push할 수 없습니다. PR 브랜치를 사용하세요." >&2
      exit 1
      ;;
  esac

  if [ "$local_sha" != "$zero_sha" ]; then
    should_run_lint=1
  fi

  if [ "$local_sha" = "$zero_sha" ]; then
    continue
  fi

  if [ "$remote_sha" = "$zero_sha" ]; then
    base_ref="$(resolve_base_ref)"
    if ! collect_changed_files_from_base "$local_sha" "$base_ref"; then
      should_run_full_lint=1
      echo "[Quality Gate] 기준 브랜치를 찾을 수 없어 전체 lint로 폴백합니다." >&2
    fi
  else
    if git cat-file -e "${remote_sha}^{commit}" 2>/dev/null; then
      git diff --name-only "$remote_sha..$local_sha" >> "$changed_files_tmp"
    else
      base_ref="$(resolve_base_ref)"
      if ! collect_changed_files_from_base "$local_sha" "$base_ref"; then
        should_run_full_lint=1
        echo "[Quality Gate] 원격 기준 SHA를 로컬에서 찾지 못해 전체 lint로 폴백합니다." >&2
      fi
    fi
  fi
done

if [ "$should_run_lint" -eq 1 ]; then
  sorted_changed_files_tmp="$(mktemp)"
  sort -u "$changed_files_tmp" > "$sorted_changed_files_tmp"

  while IFS= read -r changed_file; do
    [ -z "$changed_file" ] && continue

    case "$changed_file" in
      .github/workflows/*|melos.yaml|pubspec.yaml|*/pubspec.yaml|scripts/git-hooks/*|.husky/*)
        should_run_full_lint=1
        ;;
      app/*)
        add_lint_task "app"
        ;;
      core/*)
        core_module="$(printf "%s" "$changed_file" | cut -d/ -f2)"
        case "$core_module" in
          data|database|datastore|designsystem|domain|model|network|testing)
            add_lint_task "core/${core_module}"
            ;;
        esac
        ;;
      feature/training/api/*)
        add_lint_task "feature/training/api"
        ;;
      feature/training/entry/*)
        add_lint_task "feature/training/entry"
        ;;
      feature/training/impl/*)
        add_lint_task "feature/training/impl"
        ;;
      feature/training/*)
        should_run_full_lint=1
        ;;
      AGENTS.md|docs/agent/*|docs/agent/*/*|docs/ai-rework/*|docs/ai-rework/*/*)
        ;;
    esac
  done < "$sorted_changed_files_tmp"

  rm -f "$sorted_changed_files_tmp"

  if [ "$should_run_full_lint" -eq 1 ]; then
    echo "[Quality Gate] 변경 영향이 커서 전체 analyze를 실행합니다..."
    dart run melos run analyze
  elif [ -s "$lint_tasks_tmp" ]; then
    package_paths="$(sort -u "$lint_tasks_tmp")"
    echo "[Quality Gate] 변경 패키지 analyze를 실행합니다:"
    printf "%s\n" "$package_paths"
    for package_path in $package_paths; do
      if [ -f "${package_path}/pubspec.yaml" ]; then
        (cd "$package_path" && dart analyze .)
      fi
    done
  else
    echo "[Quality Gate] analyze 대상 변경이 없어 건너뜁니다."
  fi
fi

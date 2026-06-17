# Custom Exercise PRD/TRD

## Phase 1: Product Decision

커스텀 운동은 운동 탭에서 현재 로그인 사용자가 개인적으로 추가하는 비공개 운동이다. 기본 운동(seed)은 모든 사용자에게 보이지만, 커스텀 운동은 저장한 사용자에게만 보인다.

MVP는 친구 공유, 편집, 삭제, 서버 동기화, 플랜 편입을 포함하지 않는다. 다만 나중에 친구가 만든 운동을 공유받을 수 있도록 owner와 source를 분리해서 저장한다.

## User Flow

1. 사용자는 운동 탭 상단의 운동 추가 버튼을 누른다.
2. 폼에서 이름, 카테고리, 장비, 난이도, 설명, 운동 방법, 주의 포인트, 기본 세트/반복 또는 시간, 휴식 시간, 선택 이미지 경로를 입력한다.
3. 카테고리, 장비, 난이도, 측정 방식은 드롭다운으로 선택한다.
4. 이미지를 입력하지 않으면 기존 운동 썸네일 크기의 기본 placeholder를 사용한다.
5. 저장하면 현재 사용자 소유의 비공개 운동으로 저장되고, 운동 상세로 이동한다.
6. 운동 목록으로 돌아가면 내 운동 섹션에 방금 추가한 운동이 보인다.

## Acceptance Criteria

- 커스텀 운동 저장 시 현재 로그인 사용자를 `ownerUserId`로 기록한다.
- 운동 탭은 seed 운동과 현재 사용자가 소유한 커스텀 운동만 보여준다.
- 다른 사용자가 만든 커스텀 운동은 자동으로 보이지 않는다.
- seed 운동은 모든 사용자에게 공통으로 보인다.
- 커스텀 운동은 `source=userCreated`, `originExerciseId=null`, `sourceOwnerUserId=null`, `sourceShareId=null`로 저장된다.
- 이미지 경로가 비어 있으면 기존 고정 썸네일/스텝 이미지 프레임 안에 placeholder를 표시한다.
- 필수 입력값이 없거나 숫자 범위를 벗어나면 저장하지 않고 오류를 보여준다.
- 같은 이름의 seed 운동이나 커스텀 운동이 있어도 별도 내 운동으로 저장할 수 있다.

## Out Of Scope

- 커스텀 운동 편집/삭제
- 커스텀 운동을 플랜에 추가
- 친구에게 운동 공유
- 친구 운동 가져오기/승인
- 공유 권한 회수
- 서버 백업/동기화
- 네이티브 이미지 피커 또는 이미지 파일 복사/압축

## Ten Discussion Rounds

1. Ownership: stable product term is `ownerUserId`; current local implementation maps the active session id to that owner id.
2. Privacy: custom exercises are private by default and never auto-shared.
3. Future sharing: default future behavior should be copy/import. Shared reference stays read-only preview until a later feature.
4. Storage: follow the current in-memory DAO baseline, but make the DAO owner-scoped so isolation is testable.
5. Metadata: keep metadata grouped on `Exercise` and normalize missing metadata as seed/built-in.
6. Image: accept an optional image path as an input format, render it in fixed frames, and fall back when empty or invalid. No native picker in MVP.
7. Form design: split basic info from detail info; use dropdowns for enumerated choices and text areas for method/safety lines.
8. UX: show an add button in the exercise tab, an owned badge on custom rows/details, and a private owner context in the form.
9. Validation and tests: owner isolation is P1 and must be covered below UI and at app/widget level.
10. Scope: keep edit/delete/share/plan insertion/server sync out of this PR.

## Technical Design

### Model

`Exercise` remains the shared render model for seed and custom exercises. It gains optional source metadata and optional `imagePath`.

- Seed exercise: `metadata.source == seed`, no owner.
- User-created custom exercise: `metadata.source == userCreated`, `ownerUserId == active user id`.
- Future imported copy: new exercise id and current owner, with origin/source fields preserved.
- Future shared reference: original owner remains source owner, and write actions stay disabled.

### Domain

Add `CreateCustomExerciseUseCase` and `TrainingRepository.createCustomExercise(CustomExerciseInput input)`.

The repository, not the UI, assigns owner metadata from the active user. UI input must not allow the user to choose an owner.

### Data

Add a `CustomExerciseDao` with `observeByOwner(ownerUserId)` and `upsert(entity)`. The default repository combines seed exercises with custom exercises for the active owner only.

The current app has no real login UI, so `local-default` is the active owner fallback. Tests can switch active sessions through the datastore API to prove owner isolation.

### UI

The training controller owns form state and validation. Widgets render state and dispatch events only.

The exercise tab renders:

- Add custom exercise button
- My exercises section when custom exercises exist
- Built-in exercises grouped by muscle group

The detail page renders an owned badge and a saved message when arriving from a successful create flow.

## Validation Plan

- `core/database`: custom DAO owner filtering and emissions.
- `core/data`: create custom exercise, seed + owner merge, user A/B isolation.
- `feature/training/impl`: controller form validation and widget create flow.
- `app`: end-to-end widget happy path from the real app shell.
- `app integration_test`: smoke coverage for the app shell after the flow change.

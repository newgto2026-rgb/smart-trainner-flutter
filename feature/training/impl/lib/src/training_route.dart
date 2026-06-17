import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smart_trainner_core_designsystem/smart_trainner_core_designsystem.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_feature_training_impl/src/exercise_step_images.dart';
import 'package:smart_trainner_feature_training_impl/src/exercise_step_text.dart';
import 'package:smart_trainner_feature_training_impl/src/training_controller.dart';
import 'package:smart_trainner_feature_training_impl/src/training_ui_models.dart';

class TrainingRoute extends StatefulWidget {
  const TrainingRoute({
    required this.observeExercises,
    required this.observePlanTemplates,
    required this.observeCurrentWeeklyPlan,
    required this.observeWorkoutLogs,
    required this.observeWeeklySummary,
    required this.createCustomExercise,
    required this.selectPlanTemplate,
    required this.saveWorkoutLog,
    this.today,
    super.key,
  });

  final ObserveExercisesUseCase observeExercises;
  final ObservePlanTemplatesUseCase observePlanTemplates;
  final ObserveCurrentWeeklyPlanUseCase observeCurrentWeeklyPlan;
  final ObserveWorkoutLogsUseCase observeWorkoutLogs;
  final ObserveWeeklySummaryUseCase observeWeeklySummary;
  final CreateCustomExerciseUseCase createCustomExercise;
  final SelectPlanTemplateUseCase selectPlanTemplate;
  final SaveWorkoutLogUseCase saveWorkoutLog;
  final DateTime? today;

  @override
  State<TrainingRoute> createState() => _TrainingRouteState();
}

class _TrainingRouteState extends State<TrainingRoute> {
  late final TrainingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TrainingController(
      observeExercises: widget.observeExercises,
      observePlanTemplates: widget.observePlanTemplates,
      observeCurrentWeeklyPlan: widget.observeCurrentWeeklyPlan,
      observeWorkoutLogs: widget.observeWorkoutLogs,
      observeWeeklySummary: widget.observeWeeklySummary,
      createCustomExercise: widget.createCustomExercise,
      selectPlanTemplate: widget.selectPlanTemplate,
      saveWorkoutLog: widget.saveWorkoutLog,
      today: widget.today,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final recording = state.recordingPlannedExercise;
        final customExerciseFormVisible = state.isCustomExerciseFormVisible;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Smart Trainer', key: Key('training_app_title')),
            centerTitle: false,
          ),
          body: SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: _TrainingBody(state: state, controller: _controller),
                ),
                if (recording != null)
                  Positioned.fill(
                    child: _RecordDialogScrim(
                      state: state,
                      planned: recording,
                      controller: _controller,
                    ),
                  ),
                if (customExerciseFormVisible)
                  Positioned.fill(
                    child: _CustomExerciseDialogScrim(
                      state: state,
                      controller: _controller,
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.selectedTab.index,
            onDestinationSelected: (index) {
              _controller.selectTab(TrainingTab.values[index]);
            },
            destinations: const <Widget>[
              NavigationDestination(
                key: Key('training_tab_home'),
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: '홈',
              ),
              NavigationDestination(
                key: Key('training_tab_plan'),
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: '플랜',
              ),
              NavigationDestination(
                key: Key('training_tab_exercises'),
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: '운동',
              ),
              NavigationDestination(
                key: Key('training_tab_analysis'),
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: '분석',
              ),
            ],
          ),
          floatingActionButton: state.selectedPlannedExercise == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    _controller.selectPlannedExercise(
                      state.selectedPlannedExercise!,
                    );
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('기록'),
                ),
        );
      },
    );
  }
}

class _TrainingBody extends StatelessWidget {
  const _TrainingBody({required this.state, required this.controller});

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final selectedExercise = state.selectedExercise;
    if (state.selectedTab == TrainingTab.exercises &&
        selectedExercise != null) {
      return _ExerciseDetail(
        exercise: selectedExercise,
        showSavedMessage:
            state.lastCreatedCustomExerciseId == selectedExercise.id,
        onBack: controller.dismissExerciseDetail,
      );
    }

    return switch (state.selectedTab) {
      TrainingTab.home => _HomeTab(state: state, controller: controller),
      TrainingTab.plan => _PlanTab(state: state, controller: controller),
      TrainingTab.exercises => _ExercisesTab(
        state: state,
        controller: controller,
      ),
      TrainingTab.analysis => _AnalysisTab(state: state),
    };
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.state, required this.controller});

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedPlannedExercise;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SectionTitle(
          keyName: 'training_section_title_training_today_title',
          title: '오늘의 트레이닝',
        ),
        const SizedBox(height: 12),
        if (selected == null)
          const _EmptySurface(text: '이번 주 플랜을 준비 중입니다.')
        else
          _TodayExerciseTile(
            planned: selected,
            completed: state.completedPlannedExerciseIds.contains(selected.id),
            onRecord: () => controller.selectPlannedExercise(selected),
          ),
        const SizedBox(height: 20),
        _SectionTitle(title: '주간 진행'),
        const SizedBox(height: 12),
        _ProgressSurface(summary: state.summary),
        const SizedBox(height: 20),
        _SectionTitle(title: '최근 기록'),
        const SizedBox(height: 12),
        if (state.logs.isEmpty)
          const _EmptySurface(text: '첫 세트를 저장하면 여기에 기록이 쌓입니다.')
        else
          ...state.logs.take(5).map(_RecentLogTile.new),
      ],
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({required this.state, required this.controller});

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final plan = state.plan;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SectionTitle(title: '주간 플랜'),
        const SizedBox(height: 12),
        if (state.templates.isNotEmpty)
          _TemplateSelector(
            templates: state.templates,
            selectedTemplateId: state.selectedTemplateId,
            onSelected: controller.selectTemplate,
          ),
        const SizedBox(height: 16),
        if (plan == null)
          const _EmptySurface(text: '플랜을 불러오는 중입니다.')
        else
          ...plan.days.expand((day) {
            return <Widget>[
              _DayHeader(day: day),
              const SizedBox(height: 8),
              ...day.exercises.map((planned) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanExerciseTile(
                    planned: planned,
                    completed: state.completedPlannedExerciseIds.contains(
                      planned.id,
                    ),
                    selected: state.selectedPlannedExercise?.id == planned.id,
                    onTap: () => controller.selectPlannedExercise(planned),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ];
          }),
      ],
    );
  }
}

class _ExercisesTab extends StatelessWidget {
  const _ExercisesTab({required this.state, required this.controller});

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final customExercises = state.exercises
        .where((exercise) => exercise.metadata.isOwnedLibraryItem)
        .toList();
    final seedExercises = state.exercises
        .where((exercise) => !exercise.metadata.isOwnedLibraryItem)
        .toList();
    final grouped = <MuscleGroup, List<Exercise>>{};
    for (final exercise in seedExercises) {
      grouped
          .putIfAbsent(exercise.muscleGroup, () => <Exercise>[])
          .add(exercise);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(child: _SectionTitle(title: '운동 라이브러리')),
            FilledButton.icon(
              key: const Key('training_add_custom_exercise_button'),
              onPressed: controller.showCustomExerciseForm,
              icon: const Icon(Icons.add),
              label: const Text('운동 추가'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (customExercises.isNotEmpty) ...<Widget>[
          Text(
            '내 운동',
            key: const Key('training_my_exercises_section'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...customExercises.map((exercise) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExerciseRow(
                exercise: exercise,
                onTap: () => controller.selectExercise(exercise.id),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        for (final entry in grouped.entries) ...<Widget>[
          Text(
            entry.key.displayName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...entry.value.map((exercise) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExerciseRow(
                exercise: exercise,
                onTap: () => controller.selectExercise(exercise.id),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  const _AnalysisTab({required this.state});

  final TrainingUiState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SectionTitle(title: '분석'),
        const SizedBox(height: 12),
        _SummaryBand(summary: summary),
        const SizedBox(height: 16),
        if (summary == null)
          const _EmptySurface(text: '분석을 계산하는 중입니다.')
        else ...<Widget>[
          _MetricGrid(summary: summary),
          const SizedBox(height: 16),
          _InsightSurface(text: summary.insight),
          const SizedBox(height: 16),
          _MuscleBalance(summary: summary),
        ],
      ],
    );
  }
}

class _ExerciseDetail extends StatelessWidget {
  const _ExerciseDetail({
    required this.exercise,
    required this.showSavedMessage,
    required this.onBack,
  });

  final Exercise exercise;
  final bool showSavedMessage;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final visuals = exerciseStepVisuals(exercise.id.value);
    final steps = _stepItemsFor(exercise);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('운동 목록'),
          ),
        ),
        Text(
          exercise.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (exercise.metadata.isOwnedLibraryItem) ...<Widget>[
          const SizedBox(height: 8),
          const _SourceBadge(
            key: Key('training_exercise_source_badge_owned'),
            label: '내 운동',
          ),
        ],
        if (showSavedMessage) ...<Widget>[
          const SizedBox(height: 8),
          const Text(
            '내 운동에 저장했습니다.',
            key: Key('training_custom_exercise_saved_owner_message'),
            style: TextStyle(
              color: SmartTrainnerColors.green,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          exercise.summary,
          style: const TextStyle(color: SmartTrainnerColors.muted),
        ),
        const SizedBox(height: 16),
        _StepImageSection(exercise: exercise, visuals: visuals, steps: steps),
        const SizedBox(height: 16),
        _BulletSection(title: '안전 큐', bullets: exercise.safetyCues),
      ],
    );
  }
}

class _CustomExerciseDialogScrim extends StatelessWidget {
  const _CustomExerciseDialogScrim({
    required this.state,
    required this.controller,
  });

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: _CustomExerciseDialog(state: state, controller: controller),
      ),
    );
  }
}

class _CustomExerciseDialog extends StatelessWidget {
  const _CustomExerciseDialog({required this.state, required this.controller});

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final form = state.customExerciseForm;
    return Material(
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        key: const Key('training_custom_exercise_form'),
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '내 운동 추가',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.dismissCustomExerciseForm,
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                key: const Key('training_custom_exercise_form_scroll'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shrinkWrap: true,
                children: <Widget>[
                  const _OwnerContext(),
                  const SizedBox(height: 14),
                  _CustomExerciseImagePreview(imagePath: form.imagePath),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: '기본 정보'),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('training_custom_exercise_name_input'),
                    initialValue: form.name,
                    decoration: const InputDecoration(
                      labelText: '운동 이름',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.updateCustomExerciseName,
                  ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: CustomExerciseFormError.name,
                  ),
                  const SizedBox(height: 10),
                  _CustomExerciseDropdown<MuscleGroup>(
                    keyName: 'training_custom_exercise_muscle_group_dropdown',
                    labelText: '카테고리',
                    value: form.muscleGroup,
                    values: MuscleGroup.values,
                    displayName: (value) => value.displayName,
                    optionKey: (value) =>
                        'training_custom_exercise_muscle_group_option_${value.name}',
                    onChanged: controller.updateCustomExerciseMuscleGroup,
                  ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: CustomExerciseFormError.muscleGroup,
                  ),
                  const SizedBox(height: 10),
                  _CustomExerciseDropdown<EquipmentType>(
                    keyName: 'training_custom_exercise_equipment_dropdown',
                    labelText: '장비',
                    value: form.equipment,
                    values: EquipmentType.values,
                    displayName: (value) => value.displayName,
                    optionKey: (value) =>
                        'training_custom_exercise_equipment_option_${value.name}',
                    onChanged: controller.updateCustomExerciseEquipment,
                  ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: CustomExerciseFormError.equipment,
                  ),
                  const SizedBox(height: 10),
                  _CustomExerciseDropdown<DifficultyLevel>(
                    keyName: 'training_custom_exercise_difficulty_dropdown',
                    labelText: '난이도',
                    value: form.difficulty,
                    values: DifficultyLevel.values,
                    displayName: (value) => value.displayName,
                    optionKey: (value) =>
                        'training_custom_exercise_difficulty_option_${value.name}',
                    onChanged: controller.updateCustomExerciseDifficulty,
                  ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: CustomExerciseFormError.difficulty,
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: '상세 정보'),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('training_custom_exercise_summary_input'),
                    initialValue: form.summary,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '기본 설명',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.updateCustomExerciseSummary,
                  ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: CustomExerciseFormError.summary,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key(
                      'training_custom_exercise_instructions_input',
                    ),
                    initialValue: form.instructions,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: '운동 방법',
                      helperText: '한 줄에 한 단계씩 입력',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.updateCustomExerciseInstructions,
                  ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: CustomExerciseFormError.instructions,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('training_custom_exercise_safety_input'),
                    initialValue: form.safetyCues,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '주의 포인트',
                      helperText: '한 줄에 하나씩 입력',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.updateCustomExerciseSafetyCues,
                  ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: CustomExerciseFormError.safetyCues,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('training_custom_exercise_image_path_input'),
                    initialValue: form.imagePath,
                    decoration: const InputDecoration(
                      labelText: '이미지 경로(선택)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.updateCustomExerciseImagePath,
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: '기본 기록값'),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          key: const Key('training_custom_exercise_sets_input'),
                          initialValue: form.defaultSets,
                          decoration: const InputDecoration(
                            labelText: '세트',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: controller.updateCustomExerciseDefaultSets,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          key: const Key(
                            'training_custom_exercise_rest_seconds_input',
                          ),
                          initialValue: form.restSeconds,
                          decoration: const InputDecoration(
                            labelText: '휴식(초)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: controller.updateCustomExerciseRestSeconds,
                        ),
                      ),
                    ],
                  ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: CustomExerciseFormError.sets,
                  ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: CustomExerciseFormError.rest,
                  ),
                  const SizedBox(height: 10),
                  _CustomExerciseDropdown<CustomExerciseTargetType>(
                    keyName: 'training_custom_exercise_target_type_dropdown',
                    labelText: '측정 방식',
                    value: form.targetType,
                    values: CustomExerciseTargetType.values,
                    displayName: (value) => value.displayName,
                    optionKey: (value) =>
                        'training_custom_exercise_target_type_option_${value.name}',
                    onChanged: controller.updateCustomExerciseTargetType,
                  ),
                  const SizedBox(height: 10),
                  if (form.targetType == CustomExerciseTargetType.reps)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            key: const Key(
                              'training_custom_exercise_rep_first_input',
                            ),
                            initialValue: form.repRangeFirst,
                            decoration: const InputDecoration(
                              labelText: '최소 반복',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                controller.updateCustomExerciseRepRangeFirst,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            key: const Key(
                              'training_custom_exercise_rep_last_input',
                            ),
                            initialValue: form.repRangeLast,
                            decoration: const InputDecoration(
                              labelText: '최대 반복',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                controller.updateCustomExerciseRepRangeLast,
                          ),
                        ),
                      ],
                    )
                  else
                    TextFormField(
                      key: const Key(
                        'training_custom_exercise_duration_minutes_input',
                      ),
                      initialValue: form.durationMinutes,
                      decoration: const InputDecoration(
                        labelText: '시간(분)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: controller.updateCustomExerciseDurationMinutes,
                    ),
                  _CustomExerciseErrorText(
                    current: state.customExerciseFormError,
                    target: form.targetType == CustomExerciseTargetType.reps
                        ? CustomExerciseFormError.reps
                        : CustomExerciseFormError.duration,
                  ),
                  if (state.customExerciseFormError ==
                      CustomExerciseFormError.saveFailed) ...<Widget>[
                    const SizedBox(height: 10),
                    const Text(
                      '운동을 저장하지 못했습니다.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const Key('training_custom_exercise_save_button'),
                    onPressed: controller.saveCustomExercise,
                    icon: const Icon(Icons.check),
                    label: const Text('저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerContext extends StatelessWidget {
  const _OwnerContext();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('training_custom_exercise_owner_context'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SmartTrainnerColors.coralSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.lock_outline, color: SmartTrainnerColors.coral),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '소유자: 나 · 공개 범위: 비공개',
              key: Key('training_custom_exercise_visibility_private'),
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomExerciseImagePreview extends StatelessWidget {
  const _CustomExerciseImagePreview({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        key: const Key('training_custom_exercise_image_preview'),
        height: 132,
        color: SmartTrainnerColors.coralSoft,
        child: path.isEmpty
            ? const _CustomExerciseImagePlaceholder()
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const _CustomExerciseImagePlaceholder();
                },
              ),
      ),
    );
  }
}

class _CustomExerciseImagePlaceholder extends StatelessWidget {
  const _CustomExerciseImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.fitness_center,
        key: Key('training_custom_exercise_image_placeholder'),
        color: SmartTrainnerColors.coral,
      ),
    );
  }
}

class _CustomExerciseDropdown<T> extends StatelessWidget {
  const _CustomExerciseDropdown({
    required this.keyName,
    required this.labelText,
    required this.value,
    required this.values,
    required this.displayName,
    required this.optionKey,
    required this.onChanged,
  });

  final String keyName;
  final String labelText;
  final T? value;
  final List<T> values;
  final String Function(T value) displayName;
  final String Function(T value) optionKey;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: Key(keyName),
      initialValue: value,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      items: values.map((value) {
        return DropdownMenuItem<T>(
          value: value,
          child: Text(displayName(value), key: Key(optionKey(value))),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _CustomExerciseErrorText extends StatelessWidget {
  const _CustomExerciseErrorText({required this.current, required this.target});

  final CustomExerciseFormError? current;
  final CustomExerciseFormError target;

  @override
  Widget build(BuildContext context) {
    if (current != target) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        _customExerciseFormErrorText(target),
        key: Key('training_custom_exercise_error_${target.name}'),
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}

class _RecordDialogScrim extends StatelessWidget {
  const _RecordDialogScrim({
    required this.state,
    required this.planned,
    required this.controller,
  });

  final TrainingUiState state;
  final PlannedExercise planned;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: _RecordDialog(
          state: state,
          planned: planned,
          controller: controller,
        ),
      ),
    );
  }
}

class _RecordDialog extends StatelessWidget {
  const _RecordDialog({
    required this.state,
    required this.planned,
    required this.controller,
  });

  final TrainingUiState state;
  final PlannedExercise planned;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        key: const Key('training_record_dialog'),
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${planned.exercise.name} 기록',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.dismissRecordDialog,
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shrinkWrap: true,
                children: <Widget>[
                  _SelectedExerciseSurface(planned: planned),
                  const SizedBox(height: 14),
                  for (
                    var index = 0;
                    index < state.recordForm.setEntries.length;
                    index++
                  ) ...<Widget>[
                    _SetEntryRow(
                      index: index,
                      planned: planned,
                      entry: state.recordForm.setEntries[index],
                      onRepsChanged: (value) {
                        controller.updateSetReps(index, value);
                      },
                      onWeightChanged: (value) {
                        controller.updateSetWeight(index, value);
                      },
                      onDurationChanged: (value) {
                        controller.updateSetDuration(index, value);
                      },
                      onRemove: state.recordForm.setEntries.length <= 1
                          ? null
                          : () => controller.removeSetEntry(index),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('training_add_set_button'),
                      onPressed:
                          state.recordForm.setEntries.length >= maxRecordSets
                          ? null
                          : controller.addSetEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('세트 추가'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.recordForm.memo,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '메모',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.updateMemo,
                  ),
                  if (state.formError != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      _formErrorText(state.formError!),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  if (state.recordSaved) ...<Widget>[
                    const SizedBox(height: 10),
                    const Text(
                      '기록을 저장했습니다.',
                      key: Key('training_record_saved_message'),
                      style: TextStyle(
                        color: SmartTrainnerColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const Key('training_save_record'),
                    onPressed: controller.saveRecord,
                    icon: const Icon(Icons.check),
                    label: const Text('저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedExerciseSurface extends StatelessWidget {
  const _SelectedExerciseSurface({required this.planned});

  final PlannedExercise planned;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('training_record_selected_exercise'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SmartTrainnerColors.coralSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          _ExerciseThumb(exercise: planned.exercise),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  planned.exercise.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  planned.targetText,
                  style: const TextStyle(color: SmartTrainnerColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetEntryRow extends StatelessWidget {
  const _SetEntryRow({
    required this.index,
    required this.planned,
    required this.entry,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onDurationChanged,
    required this.onRemove,
  });

  final int index;
  final PlannedExercise planned;
  final RecordSetFormState entry;
  final ValueChanged<String> onRepsChanged;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onDurationChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final usesReps = planned.repRange != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 34,
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        if (usesReps) ...<Widget>[
          Expanded(
            child: TextFormField(
              key: Key('training_set_reps_input_$index'),
              initialValue: entry.reps,
              decoration: const InputDecoration(
                labelText: '회',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: onRepsChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: Key('training_set_weight_input_$index'),
              initialValue: entry.weightKg,
              decoration: const InputDecoration(
                labelText: 'kg',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: onWeightChanged,
            ),
          ),
        ] else
          Expanded(
            child: TextFormField(
              key: Key('training_set_duration_input_$index'),
              initialValue: entry.durationMinutes,
              decoration: const InputDecoration(
                labelText: '분',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: onDurationChanged,
            ),
          ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: '세트 제거',
        ),
      ],
    );
  }
}

class _TemplateSelector extends StatelessWidget {
  const _TemplateSelector({
    required this.templates,
    required this.selectedTemplateId,
    required this.onSelected,
  });

  final List<PlanTemplate> templates;
  final String selectedTemplateId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: templates.map((template) {
        return ChoiceChip(
          label: Text(template.name),
          selected: template.id == selectedTemplateId,
          onSelected: (_) => onSelected(template.id),
        );
      }).toList(),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final WorkoutDayPlan day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              day.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            day.focus,
            style: const TextStyle(color: SmartTrainnerColors.muted),
          ),
        ],
      ),
    );
  }
}

class _TodayExerciseTile extends StatelessWidget {
  const _TodayExerciseTile({
    required this.planned,
    required this.completed,
    required this.onRecord,
  });

  final PlannedExercise planned;
  final bool completed;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Row(
        children: <Widget>[
          _ExerciseThumb(exercise: planned.exercise),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  planned.exercise.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${planned.targetText} · 휴식 ${planned.restSeconds}초',
                  style: const TextStyle(color: SmartTrainnerColors.muted),
                ),
                if (planned.note.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(planned.note),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onRecord,
            icon: Icon(completed ? Icons.done : Icons.add_task),
            label: Text(completed ? '완료' : '기록'),
          ),
        ],
      ),
    );
  }
}

class _PlanExerciseTile extends StatelessWidget {
  const _PlanExerciseTile({
    required this.planned,
    required this.completed,
    required this.selected,
    required this.onTap,
  });

  final PlannedExercise planned;
  final bool completed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SmartTrainnerColors.coralSoft : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('training_plan_exercise_${planned.exercise.id.value}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Icon(
                completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: completed
                    ? SmartTrainnerColors.green
                    : SmartTrainnerColors.muted,
              ),
              const SizedBox(width: 10),
              _ExerciseThumb(exercise: planned.exercise),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      planned.exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      planned.targetText,
                      style: const TextStyle(color: SmartTrainnerColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOwned = exercise.metadata.isOwnedLibraryItem;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('training_exercise_row_${exercise.id.value}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              _ExerciseThumb(exercise: exercise),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (isOwned) ...<Widget>[
                      const SizedBox(height: 4),
                      const _SourceBadge(label: '내 운동'),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      '${isOwned ? '내 운동 · ' : ''}'
                      '${exercise.equipment.displayName} · ${exercise.targetText}',
                      style: const TextStyle(color: SmartTrainnerColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SmartTrainnerColors.coralSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: SmartTrainnerColors.coral,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  const _ExerciseThumb({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final assetPath = exerciseThumbnailAssetPath(exercise.id.value);
    final imagePath = exercise.imagePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        key: Key('training_exercise_thumb_${exercise.id.value}'),
        width: 58,
        height: 58,
        color: SmartTrainnerColors.coralSoft,
        child: imagePath != null && imagePath.trim().isNotEmpty
            ? Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _ExerciseThumbPlaceholder(exercise: exercise);
                },
              )
            : assetPath == null
            ? _ExerciseThumbPlaceholder(exercise: exercise)
            : Image.asset(
                assetPath,
                package: 'smart_trainner_feature_training_impl',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _ExerciseThumbPlaceholder extends StatelessWidget {
  const _ExerciseThumbPlaceholder({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: Key('training_exercise_thumb_placeholder_${exercise.id.value}'),
      child: Text(
        exercise.name.isEmpty ? '?' : exercise.name.substring(0, 1),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StepImageSection extends StatelessWidget {
  const _StepImageSection({
    required this.exercise,
    required this.visuals,
    required this.steps,
  });

  final Exercise exercise;
  final List<ExerciseStepVisual> visuals;
  final List<_LocalizedExerciseStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const _EmptySurface(text: '운동 설명을 준비 중입니다.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(title: '동작 순서'),
        const SizedBox(height: 10),
        for (var index = 0; index < steps.length; index++) ...<Widget>[
          _StepTile(
            index: index,
            exercise: exercise,
            step: steps[index],
            visual: index < visuals.length ? visuals[index] : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.exercise,
    required this.step,
    required this.visual,
  });

  final int index;
  final Exercise exercise;
  final _LocalizedExerciseStep step;
  final ExerciseStepVisual? visual;

  @override
  Widget build(BuildContext context) {
    final visual = this.visual;
    return _Surface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              key: Key('training_step_image_$index'),
              width: 86,
              height: 96,
              color: SmartTrainnerColors.coralSoft,
              child: visual == null
                  ? const Icon(Icons.fitness_center)
                  : Image.asset(
                      visual.assetPath,
                      package: 'smart_trainner_feature_training_impl',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${index + 1}. ${step.label}',
                  style: const TextStyle(
                    color: SmartTrainnerColors.coral,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(step.instruction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(title: title),
        const SizedBox(height: 8),
        for (final bullet in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $bullet'),
          ),
      ],
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.summary});

  final WeeklySummary? summary;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    return Container(
      key: const Key('training_summary_band'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SmartTrainnerColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.insights, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary == null
                  ? '분석 준비 중'
                  : '이번 주 완료율 ${summary.completionRate}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summary});

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: <Widget>[
        _MetricTile(label: '완료', value: '${summary.completedExerciseCount}개'),
        _MetricTile(label: '세트', value: '${summary.totalSets}'),
        _MetricTile(
          label: '볼륨',
          value: '${summary.totalVolumeKg.toStringAsFixed(0)}kg',
        ),
        _MetricTile(label: '시간', value: '${summary.totalMinutes}분'),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(label, style: const TextStyle(color: SmartTrainnerColors.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MuscleBalance extends StatelessWidget {
  const _MuscleBalance({required this.summary});

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(title: '근육 균형'),
        const SizedBox(height: 8),
        for (final muscle in MuscleGroup.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                SizedBox(width: 70, child: Text(muscle.displayName)),
                Expanded(
                  child: LinearProgressIndicator(
                    value:
                        (summary.muscleBalance[muscle] ?? 0) /
                        summary.completedExerciseCount.clamp(1, 99),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${summary.muscleBalance[muscle] ?? 0}'),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentLogTile extends StatelessWidget {
  const _RecentLogTile(this.log);

  final WorkoutLog log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Surface(
        child: Row(
          children: <Widget>[
            const Icon(Icons.check_circle, color: SmartTrainnerColors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${log.sets}세트 저장 · ${log.performedAt.dateLabel}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSurface extends StatelessWidget {
  const _ProgressSurface({required this.summary});

  final WeeklySummary? summary;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    final progress = summary == null ? 0.0 : summary.completionRate / 100;
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            summary == null ? '완료율 0%' : '완료율 ${summary.completionRate}%',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}

class _InsightSurface extends StatelessWidget {
  const _InsightSurface({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}

class _EmptySurface extends StatelessWidget {
  const _EmptySurface({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Text(
        text,
        style: const TextStyle(color: SmartTrainnerColors.muted),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SmartTrainnerColors.surfaceRaised,
        border: Border.all(color: SmartTrainnerColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.keyName});

  final String title;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      key: keyName == null ? null : Key(keyName!),
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _LocalizedExerciseStep {
  const _LocalizedExerciseStep({
    required this.label,
    required this.instruction,
  });

  final String label;
  final String instruction;
}

List<_LocalizedExerciseStep> _stepItemsFor(Exercise exercise) {
  final visuals = exerciseStepVisuals(exercise.id.value);
  if (visuals.isNotEmpty) {
    return visuals.map((visual) {
      return _LocalizedExerciseStep(
        label: visual.koLabel,
        instruction: instructionWithoutRepeatedStepTitle(
          visual.koLabel,
          visual.koInstruction,
        ),
      );
    }).toList();
  }
  return exercise.instructions.map((instruction) {
    final colonIndex = instruction.indexOf(':');
    if (colonIndex > 0) {
      final label = instruction.substring(0, colonIndex).trim();
      return _LocalizedExerciseStep(
        label: label,
        instruction: instructionWithoutRepeatedStepTitle(label, instruction),
      );
    }
    return _LocalizedExerciseStep(label: '동작', instruction: instruction.trim());
  }).toList();
}

String _formErrorText(RecordFormError error) {
  return switch (error) {
    RecordFormError.selectExercise => '운동을 선택해 주세요.',
    RecordFormError.sets => '세트는 1개 이상 12개 이하로 입력해 주세요.',
    RecordFormError.reps => '반복 횟수는 1회 이상 50회 이하로 입력해 주세요.',
    RecordFormError.weight => '무게는 0kg 이상으로 입력해 주세요.',
    RecordFormError.duration => '시간은 1분 이상 240분 이하로 입력해 주세요.',
    RecordFormError.saveFailed => '기록 저장에 실패했습니다.',
  };
}

String _customExerciseFormErrorText(CustomExerciseFormError error) {
  return switch (error) {
    CustomExerciseFormError.name => '운동 이름을 입력해 주세요.',
    CustomExerciseFormError.muscleGroup => '카테고리를 선택해 주세요.',
    CustomExerciseFormError.equipment => '장비를 선택해 주세요.',
    CustomExerciseFormError.difficulty => '난이도를 선택해 주세요.',
    CustomExerciseFormError.summary => '기본 설명을 입력해 주세요.',
    CustomExerciseFormError.instructions => '운동 방법을 한 줄 이상 입력해 주세요.',
    CustomExerciseFormError.safetyCues => '주의 포인트를 한 줄 이상 입력해 주세요.',
    CustomExerciseFormError.sets => '세트는 1개 이상 12개 이하로 입력해 주세요.',
    CustomExerciseFormError.reps => '반복 범위는 1회 이상 50회 이하로 입력해 주세요.',
    CustomExerciseFormError.duration => '시간은 1분 이상 240분 이하로 입력해 주세요.',
    CustomExerciseFormError.rest => '휴식은 15초 이상 600초 이하로 입력해 주세요.',
    CustomExerciseFormError.saveFailed => '운동 저장에 실패했습니다.',
  };
}

extension on DateTime {
  String get dateLabel => '$month/$day';
}

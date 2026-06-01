import 'package:flutter/material.dart';
import 'package:smart_trainner_core_designsystem/smart_trainner_core_designsystem.dart';
import 'package:smart_trainner_core_domain/smart_trainner_core_domain.dart';
import 'package:smart_trainner_core_model/smart_trainner_core_model.dart';
import 'package:smart_trainner_core_ui/smart_trainner_core_ui.dart';
import 'package:smart_trainner_feature_routine_domain/smart_trainner_feature_routine_domain.dart';
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
    required this.selectPlanTemplate,
    required this.saveWorkoutLog,
    required this.saveCustomRoutine,
    this.today,
    super.key,
  });

  final ObserveExercisesUseCase observeExercises;
  final ObservePlanTemplatesUseCase observePlanTemplates;
  final ObserveCurrentWeeklyPlanUseCase observeCurrentWeeklyPlan;
  final ObserveWorkoutLogsUseCase observeWorkoutLogs;
  final ObserveWeeklySummaryUseCase observeWeeklySummary;
  final SelectPlanTemplateUseCase selectPlanTemplate;
  final SaveWorkoutLogUseCase saveWorkoutLog;
  final SaveCustomRoutineUseCase saveCustomRoutine;
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
      selectPlanTemplate: widget.selectPlanTemplate,
      saveWorkoutLog: widget.saveWorkoutLog,
      saveCustomRoutine: widget.saveCustomRoutine,
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
        final detailDialogExercise = state.detailDialogExercise;
        final imageViewerExercise = state.imageViewerExercise;
        return Stack(
          children: <Widget>[
            Scaffold(
              backgroundColor: SmartTrainnerColors.paper,
              body: SafeArea(
                child: _TrainingBody(state: state, controller: _controller),
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
                    label: '루틴',
                  ),
                  NavigationDestination(
                    key: Key('training_tab_exercises'),
                    icon: Icon(Icons.fitness_center_outlined),
                    selectedIcon: Icon(Icons.fitness_center),
                    label: '운동',
                  ),
                  NavigationDestination(
                    key: Key('training_tab_analysis'),
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: '분석',
                  ),
                ],
              ),
            ),
            if (recording != null)
              Positioned.fill(
                child: _RecordDialogScrim(
                  state: state,
                  planned: recording,
                  controller: _controller,
                ),
              ),
            if (state.routineLibraryVisible)
              Positioned.fill(
                child: _RoutineLibraryDialogScrim(
                  state: state,
                  controller: _controller,
                ),
              ),
            if (state.routineSettingsVisible)
              Positioned.fill(
                child: _RoutineSettingsDialogScrim(controller: _controller),
              ),
            if (state.routineRecommendationsVisible)
              Positioned.fill(
                child: _RoutineRecommendationsDialogScrim(
                  state: state,
                  controller: _controller,
                ),
              ),
            if (state.customRoutineBuilder.visible)
              Positioned.fill(
                child: _CustomRoutineBuilderScrim(
                  state: state,
                  controller: _controller,
                ),
              ),
            if (detailDialogExercise != null)
              Positioned.fill(
                child: _ExerciseDetailDialogScrim(
                  exercise: detailDialogExercise,
                  controller: _controller,
                ),
              ),
            if (imageViewerExercise != null &&
                state.imageViewerStepIndex != null)
              Positioned.fill(
                child: _ExerciseImageViewerScrim(
                  exercise: imageViewerExercise,
                  stepIndex: state.imageViewerStepIndex!,
                  controller: _controller,
                ),
              ),
          ],
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

SmartTrainnerScreenChrome _screenChrome(TrainingUiState state) {
  return SmartTrainnerScreenChrome(
    title: '스마트 트레이너',
    subtitle: state.activeRoutineTemplate?.name ?? '초보자 전신 3일 루틴',
  );
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.state, required this.controller});

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final routineDay = _currentRoutineDayPlan(state);
    final template = state.activeRoutineTemplate;
    return SmartTrainnerScreenScaffold(
      chrome: _screenChrome(state),
      children: <Widget>[
        _SectionTitle(
          keyName: 'training_section_title_today',
          title: '오늘의 트레이닝',
        ),
        const SizedBox(height: 12),
        if (routineDay == null || template == null)
          const _EmptySurface(text: '이번 주 플랜을 준비 중입니다.')
        else
          _NextRoutineDayCard(
            template: template,
            day: routineDay,
            completedIds: state.completedPlannedExerciseIds,
            onStartWorkout: controller.startWorkoutForActiveRoutineDay,
            onCompleteDay: controller.completeRoutineDay,
          ),
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
    final plan = _activeRoutinePlan(state);
    final activeTemplate = state.activeRoutineTemplate;
    return SmartTrainnerScreenScaffold(
      chrome: _screenChrome(state),
      children: <Widget>[
        _SectionTitle(title: '현재 루틴'),
        const SizedBox(height: 12),
        if (activeTemplate != null)
          _CurrentRoutineCard(
            template: activeTemplate,
            onEditCustom: activeTemplate.source == RoutineSource.custom
                ? () => controller.editCustomRoutine(activeTemplate.id)
                : null,
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('training_find_routine_button'),
          onPressed: controller.openRoutineLibrary,
          icon: const Icon(Icons.fitness_center),
          label: const Text('루틴 바꾸기'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('training_create_custom_routine_button'),
          onPressed: controller.openNewCustomRoutineBuilder,
          icon: const Icon(Icons.add),
          label: const Text('내 루틴 만들기'),
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: '루틴 일정'),
        const SizedBox(height: 12),
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
    final grouped = <MuscleGroup, List<Exercise>>{};
    for (final exercise in state.exercises) {
      grouped
          .putIfAbsent(exercise.muscleGroup, () => <Exercise>[])
          .add(exercise);
    }

    return SmartTrainnerScreenScaffold(
      chrome: _screenChrome(state),
      children: <Widget>[
        _SectionTitle(title: '전체 운동 ${state.exercises.length}개'),
        const SizedBox(height: 12),
        const _EmptySurface(text: '운동을 선택하면 자세한 동작을 확인할 수 있습니다.'),
        const SizedBox(height: 12),
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
    return SmartTrainnerScreenScaffold(
      chrome: const SmartTrainnerScreenChrome(
        title: '트레이닝 분석',
        subtitle: '이번 주 진행, 부위 균형, 최근 기록',
      ),
      children: <Widget>[
        _SummaryBand(summary: summary),
        if (state.logs.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _RecentRecordsCard(logs: state.logs, plan: state.plan),
        ],
        const SizedBox(height: 14),
        if (summary == null)
          const _EmptySurface(text: '분석을 계산하는 중입니다.')
        else
          _MuscleBalance(summary: summary),
      ],
    );
  }
}

class _ExerciseDetail extends StatelessWidget {
  const _ExerciseDetail({
    required this.exercise,
    required this.onStepImageTap,
    this.showHeader = true,
  });

  final Exercise exercise;
  final void Function(Exercise exercise, int stepIndex) onStepImageTap;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final visuals = exerciseStepVisuals(exercise.id.value);
    final steps = _stepItemsFor(exercise);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 216,
              height: 240,
              child: _ExerciseImage(exercise: exercise, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (showHeader) ...<Widget>[
          Text(
            exercise.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _ExerciseMetaChips(exercise: exercise),
          const SizedBox(height: 12),
        ],
        Text(
          exercise.summary,
          style: const TextStyle(color: SmartTrainnerColors.muted),
        ),
        const SizedBox(height: 16),
        _StepImageSection(
          exercise: exercise,
          visuals: visuals,
          steps: steps,
          onStepImageTap: onStepImageTap,
        ),
        const SizedBox(height: 16),
        _BulletSection(title: '안전 큐', bullets: exercise.safetyCues),
      ],
    );
  }
}

class _ExerciseDetailDialogScrim extends StatelessWidget {
  const _ExerciseDetailDialogScrim({
    required this.exercise,
    required this.controller,
  });

  final Exercise exercise;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          color: SmartTrainnerColors.surfaceRaised,
          child: ConstrainedBox(
            key: const Key('training_exercise_detail_dialog'),
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            _ExerciseMetaChips(exercise: exercise),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('training_close_exercise_detail'),
                        onPressed: controller.dismissExerciseMethodDialog,
                        icon: const Icon(Icons.close),
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _ExerciseDetail(
                    exercise: exercise,
                    onStepImageTap: controller.showImageViewer,
                    showHeader: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseImageViewerScrim extends StatelessWidget {
  const _ExerciseImageViewerScrim({
    required this.exercise,
    required this.stepIndex,
    required this.controller,
  });

  final Exercise exercise;
  final int stepIndex;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final visuals = exerciseStepVisuals(exercise.id.value);
    final visual = stepIndex < visuals.length ? visuals[stepIndex] : null;
    return ColoredBox(
      key: const Key('training_exercise_image_viewer'),
      color: Colors.black54,
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          color: SmartTrainnerColors.surfaceRaised,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '운동 이미지 ${stepIndex + 1}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: SmartTrainnerColors.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('training_close_exercise_image_viewer'),
                        onPressed: controller.dismissImageViewer,
                        icon: const Icon(Icons.close),
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Center(
                      child: visual == null
                          ? const Icon(Icons.fitness_center, size: 96)
                          : Image.asset(
                              visual.assetPath,
                              key: const Key(
                                'training_exercise_image_viewer_image',
                              ),
                              package: 'smart_trainner_feature_training_impl',
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('training_show_exercise_method'),
                      onPressed: controller.showExerciseMethodForRecording,
                      icon: const Icon(Icons.article_outlined),
                      label: const Text('운동 방법'),
                    ),
                  ),
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
                      onRestChanged: (value) {
                        controller.updateSetRest(index, value);
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

class _RoutineLibraryDialogScrim extends StatelessWidget {
  const _RoutineLibraryDialogScrim({
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
        child: Material(
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          color: SmartTrainnerColors.surface,
          child: ConstrainedBox(
            key: const Key('training_routine_library_dialog'),
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            child: Column(
              children: <Widget>[
                _DialogHeader(
                  title: '루틴 선택',
                  onClose: controller.dismissRoutineLibrary,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: <Widget>[
                      _DialogSectionTitle(text: '내 루틴'),
                      const SizedBox(height: 12),
                      if (state.customTemplates.isEmpty)
                        const _EmptySurface(
                          text: '아직 만든 루틴이 없어요. 좋아하는 운동으로 만들거나 기본 루틴을 복사해 보세요.',
                        )
                      else
                        for (final template in state.customTemplates)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              children: <Widget>[
                                _RoutineTemplateCard(
                                  template: template,
                                  cardKey: const Key(
                                    'training_custom_template_card',
                                  ),
                                  selected:
                                      template.id ==
                                      state.activeRoutineTemplateId,
                                  onTap: () => controller.selectRoutineTemplate(
                                    template.id,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  key: const Key(
                                    'training_edit_custom_template_card',
                                  ),
                                  onPressed: () =>
                                      controller.editCustomRoutine(template.id),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('수정'),
                                ),
                              ],
                            ),
                          ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key(
                          'training_create_custom_routine_from_library_button',
                        ),
                        onPressed: controller.openNewCustomRoutineBuilder,
                        icon: const Icon(Icons.add),
                        label: const Text('내 루틴 만들기'),
                      ),
                      const SizedBox(height: 18),
                      _DialogSectionTitle(text: '기본 루틴'),
                      const SizedBox(height: 12),
                      for (final template in state.templates)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            children: <Widget>[
                              _RoutineTemplateCard(
                                template: template,
                                cardKey: Key(
                                  'training_template_card_${template.id}',
                                ),
                                selected:
                                    template.id ==
                                    state.activeRoutineTemplateId,
                                onTap: () => controller.selectRoutineTemplate(
                                  template.id,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                key: Key(
                                  'training_copy_template_${template.id}',
                                ),
                                onPressed: () => controller
                                    .copyTemplateToCustom(template.id),
                                icon: const Icon(Icons.copy),
                                label: const Text('내 루틴으로 복사'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton.icon(
                    key: const Key('training_find_recommended_routine_button'),
                    onPressed: controller.openRoutineSettings,
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('추천으로 찾기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineSettingsDialogScrim extends StatelessWidget {
  const _RoutineSettingsDialogScrim({required this.controller});

  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          color: SmartTrainnerColors.surface,
          child: ConstrainedBox(
            key: const Key('training_routine_settings_dialog'),
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.84,
            ),
            child: Column(
              children: <Widget>[
                _DialogHeader(
                  title: '운동 설정',
                  onClose: controller.dismissRoutineLibrary,
                ),
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '먼저 루틴 조건을 정합니다. 현재 루틴은 추천을 고르고 시작하기 전까지 바뀌지 않습니다.',
                          style: TextStyle(color: SmartTrainnerColors.muted),
                        ),
                        SizedBox(height: 14),
                        _RoutineOptionPreview(
                          title: '일주일 운동 가능 횟수',
                          options: <String>['주 2회', '주 3회', '주 4회', '주 5회'],
                          selectedIndex: 2,
                        ),
                        SizedBox(height: 12),
                        _RoutineOptionPreview(
                          title: '한 번 운동 시간',
                          options: <String>['30분', '45분', '60분'],
                          selectedIndex: 2,
                        ),
                        SizedBox(height: 12),
                        _RoutineOptionPreview(
                          title: '운동 경험',
                          options: <String>['거의 처음', '꾸준히 해봄'],
                          selectedIndex: 0,
                        ),
                        SizedBox(height: 12),
                        _RoutineOptionPreview(
                          title: '원하는 운동 느낌',
                          options: <String>[
                            '앱이 추천해줘',
                            '매번 전신을 골고루',
                            '오늘의 부위를 집중',
                          ],
                          selectedIndex: 0,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.dismissRoutineLibrary,
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          key: const Key('training_show_recommendations'),
                          onPressed: controller.showRoutineRecommendations,
                          child: const Text('추천 루틴 보기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineRecommendationsDialogScrim extends StatelessWidget {
  const _RoutineRecommendationsDialogScrim({
    required this.state,
    required this.controller,
  });

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final template = state.recommendedRoutineTemplate;
    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          color: SmartTrainnerColors.surface,
          child: ConstrainedBox(
            key: const Key('training_routine_recommendations_dialog'),
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: ListView(
              padding: const EdgeInsets.all(18),
              shrinkWrap: true,
              children: <Widget>[
                _DialogHeader(
                  title: '추천 루틴 선택',
                  onClose: controller.dismissRoutineLibrary,
                ),
                const SizedBox(height: 12),
                const Text(
                  '주 4회, 1회 약 60분 기준으로 골랐습니다.',
                  style: TextStyle(color: SmartTrainnerColors.muted),
                ),
                const SizedBox(height: 14),
                const _DialogSectionTitle(text: '추천 루틴'),
                const SizedBox(height: 12),
                if (template != null)
                  _RoutineTemplateCard(
                    template: template,
                    cardKey: Key('training_routine_preview_${template.id}'),
                    selected: true,
                    onTap: controller.startRecommendedRoutine,
                  ),
                if (template != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _RoutinePreviewSchedule(template: template),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('training_start_preview_routine'),
                  onPressed: controller.startRecommendedRoutine,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('이 루틴 시작'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineTemplateCard extends StatelessWidget {
  const _RoutineTemplateCard({
    required this.template,
    required this.cardKey,
    required this.onTap,
    this.selected = false,
  });

  final PlanTemplate template;
  final Key cardKey;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: cardKey,
      color: selected
          ? SmartTrainnerColors.coralSoft
          : SmartTrainnerColors.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? SmartTrainnerColors.coral
                  : SmartTrainnerColors.line,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (selected)
                    const _Badge(
                      label: '선택됨',
                      icon: Icons.check_circle,
                      backgroundColor: SmartTrainnerColors.greenSoft,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _Badge(
                key: template.source == RoutineSource.custom
                    ? const Key('training_routine_source_custom')
                    : const Key('training_routine_source_default'),
                label: template.source == RoutineSource.custom
                    ? '사용자 루틴'
                    : '앱 기본 루틴',
                icon: template.source == RoutineSource.custom
                    ? Icons.edit
                    : Icons.fitness_center,
                backgroundColor: template.source == RoutineSource.custom
                    ? SmartTrainnerColors.greenSoft
                    : SmartTrainnerColors.coralSoft,
              ),
              const SizedBox(height: 8),
              _RoutineTemplateBadges(template: template),
              const SizedBox(height: 8),
              if (template.source == RoutineSource.system) ...<Widget>[
                Text(
                  _routineStructureLabel(template.structure),
                  style: const TextStyle(
                    color: SmartTrainnerColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _RoutineFlow(template: template),
              const SizedBox(height: 8),
              Text(
                template.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: SmartTrainnerColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutinePreviewSchedule extends StatelessWidget {
  const _RoutinePreviewSchedule({required this.template});

  final PlanTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _DialogSectionTitle(text: '루틴 미리보기'),
        const SizedBox(height: 8),
        for (final day in template.days)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SmartTrainnerColors.surfaceRaised,
                border: Border.all(color: SmartTrainnerColors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    day.primaryFocus == null
                        ? 'Day ${day.dayNumber}'
                        : 'Day ${day.dayNumber} · ${_routineFocusShortLabel(day.primaryFocus!)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${day.exercises.length}개 운동',
                    style: const TextStyle(color: SmartTrainnerColors.muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CustomRoutineBuilderScrim extends StatelessWidget {
  const _CustomRoutineBuilderScrim({
    required this.state,
    required this.controller,
  });

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final builder = state.customRoutineBuilder;
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          color: SmartTrainnerColors.surfaceRaised,
          child: ConstrainedBox(
            key: const Key('training_custom_routine_builder'),
            constraints: BoxConstraints(
              maxWidth: 680,
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '새 루틴 만들기',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '1일차, 2일차처럼 반복할 운동 순서를 직접 구성해요.',
                              style: TextStyle(
                                color: SmartTrainnerColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('training_close_custom_routine_builder'),
                        onPressed: controller.dismissCustomRoutineBuilder,
                        icon: const Icon(Icons.close),
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          key: const Key('training_custom_routine_name'),
                          initialValue: builder.name,
                          decoration: const InputDecoration(labelText: '루틴 이름'),
                          textInputAction: TextInputAction.done,
                          onChanged: controller.updateCustomRoutineName,
                        ),
                        const SizedBox(height: 14),
                        _CustomDayTabs(
                          builder: builder,
                          controller: controller,
                        ),
                        const SizedBox(height: 14),
                        _CustomDayEditor(state: state, controller: controller),
                        const SizedBox(height: 14),
                        _CustomExercisePicker(
                          state: state,
                          controller: controller,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('training_remove_custom_day'),
                          onPressed: builder.days.length > 1
                              ? () => controller.removeCustomDay(
                                  builder.selectedDayIndex,
                                )
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('일차 삭제'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('training_save_custom_routine'),
                          onPressed: controller.saveCustomRoutine,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('저장'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomDayTabs extends StatelessWidget {
  const _CustomDayTabs({required this.builder, required this.controller});

  final CustomRoutineBuilderState builder;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final entries = builder.days.indexed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '루틴 일차',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final row in entries.chunked(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                for (final entry in row) ...<Widget>[
                  Expanded(
                    child: ChoiceChip(
                      key: Key('training_custom_day_tab_${entry.$1}'),
                      label: Text('${entry.$1 + 1}일차'),
                      selected: entry.$1 == builder.selectedDayIndex,
                      onSelected: (_) => controller.selectCustomDay(entry.$1),
                    ),
                  ),
                  if (entry != row.last) const SizedBox(width: 8),
                ],
                if (row.length < 3)
                  for (var i = row.length; i < 3; i++) ...<Widget>[
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox.shrink()),
                  ],
              ],
            ),
          ),
        if (builder.days.length < 7)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('training_add_custom_day'),
              onPressed: controller.addCustomDay,
              icon: const Icon(Icons.add),
              label: const Text('일차 추가'),
            ),
          ),
      ],
    );
  }
}

class _CustomDayEditor extends StatelessWidget {
  const _CustomDayEditor({required this.state, required this.controller});

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final builder = state.customRoutineBuilder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${builder.selectedDayIndex + 1}일차 편집 중',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _CustomFocusSelector(builder: builder, controller: controller),
        const SizedBox(height: 8),
        _CustomSelectedExerciseList(state: state, controller: controller),
      ],
    );
  }
}

class _CustomFocusSelector extends StatelessWidget {
  const _CustomFocusSelector({required this.builder, required this.controller});

  final CustomRoutineBuilderState builder;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final focus = builder.selectedDay.focus;
    final selectedText = focus == null ? '설정 안 함' : routineFocusLabel(focus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Material(
          color: SmartTrainnerColors.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            key: const Key('training_custom_focus_selector'),
            borderRadius: BorderRadius.circular(8),
            onTap: controller.toggleCustomFocusMenu,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: focus == null
                      ? SmartTrainnerColors.line
                      : SmartTrainnerColors.green,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '주요 부위',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: SmartTrainnerColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedText,
                          key: Key(
                            focus == null
                                ? 'training_custom_focus_selected_none'
                                : 'training_custom_focus_selected_${_routineFocusTag(focus)}',
                          ),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: SmartTrainnerColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (builder.focusMenuVisible) ...<Widget>[
          const SizedBox(height: 8),
          Container(
            key: const Key('training_custom_focus_menu'),
            decoration: BoxDecoration(
              color: SmartTrainnerColors.surface,
              border: Border.all(color: SmartTrainnerColors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _CustomFocusMenuItem(
                      label: '설정 안 함',
                      selected: focus == null,
                      keyName: 'training_custom_focus_none',
                      onTap: () => controller.selectCustomFocus(null),
                    ),
                    for (final option in _customFocusOptions)
                      _CustomFocusMenuItem(
                        label: routineFocusLabel(option),
                        selected: focus == option,
                        keyName:
                            'training_custom_focus_${_routineFocusTag(option)}',
                        onTap: () => controller.selectCustomFocus(option),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CustomFocusMenuItem extends StatelessWidget {
  const _CustomFocusMenuItem({
    required this.label,
    required this.selected,
    required this.keyName,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String keyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key(keyName),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              child: selected
                  ? const Icon(Icons.check, color: SmartTrainnerColors.green)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _CustomSelectedExerciseList extends StatelessWidget {
  const _CustomSelectedExerciseList({
    required this.state,
    required this.controller,
  });

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final builder = state.customRoutineBuilder;
    final selectedDay = builder.selectedDay;
    if (selectedDay.exercises.isEmpty) {
      return const Text(
        '이 일차에는 아직 운동이 없어요.',
        key: Key('training_custom_day_empty'),
        style: TextStyle(color: SmartTrainnerColors.muted),
      );
    }
    final exercisesById = <ExerciseId, Exercise>{
      for (final exercise in state.exercises) exercise.id: exercise,
    };
    return Column(
      children: selectedDay.exercises.indexed.map((entry) {
        final index = entry.$1;
        final exerciseId = entry.$2;
        final exercise = exercisesById[exerciseId];
        if (exercise == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            key: Key('training_custom_exercise_${exercise.id.value}_$index'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SmartTrainnerColors.surface,
              border: Border.all(color: SmartTrainnerColors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exercise.targetText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SmartTrainnerColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('training_custom_move_up_$index'),
                  onPressed: index == 0
                      ? null
                      : () => controller.moveCustomExerciseUp(index),
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: '위로',
                ),
                IconButton(
                  key: Key('training_custom_move_down_$index'),
                  onPressed: index == selectedDay.exercises.length - 1
                      ? null
                      : () => controller.moveCustomExerciseDown(index),
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: '아래로',
                ),
                IconButton(
                  key: Key('training_remove_custom_exercise_$index'),
                  onPressed: () => controller.removeCustomExercise(index),
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: '세트 삭제',
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CustomExercisePicker extends StatelessWidget {
  const _CustomExercisePicker({required this.state, required this.controller});

  final TrainingUiState state;
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final builder = state.customRoutineBuilder;
    final focus = builder.selectedDay.focus;
    final selectedIds = builder.selectedDay.exercises.toSet();
    final allowedGroups = _allowedCustomRoutineMuscleGroups(focus);
    final availableExercises = state.exercises
        .where((exercise) => allowedGroups.contains(exercise.muscleGroup))
        .where((exercise) => !selectedIds.contains(exercise.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '이 일차에 운동 추가',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (availableExercises.isEmpty)
          Text(
            focus == null
                ? '이 일차에는 카탈로그 운동을 모두 추가했어요.'
                : '선택한 주요 부위의 운동은 이 일차에 모두 추가했어요.',
            key: const Key('training_custom_all_exercises_added'),
            style: const TextStyle(color: SmartTrainnerColors.muted),
          ),
        for (final group in MuscleGroup.values)
          if (allowedGroups.contains(group) &&
              availableExercises.any(
                (exercise) => exercise.muscleGroup == group,
              ))
            _CustomExerciseGroup(
              group: group,
              exercises: availableExercises
                  .where((exercise) => exercise.muscleGroup == group)
                  .toList(),
              expanded: builder.expandedExerciseGroups.contains(group),
              onToggle: () => controller.toggleCustomExerciseGroup(group),
              onAddExercise: controller.addCustomExercise,
              onViewExercise: controller.showExerciseMethod,
            ),
      ],
    );
  }
}

class _CustomExerciseGroup extends StatelessWidget {
  const _CustomExerciseGroup({
    required this.group,
    required this.exercises,
    required this.expanded,
    required this.onToggle,
    required this.onAddExercise,
    required this.onViewExercise,
  });

  final MuscleGroup group;
  final List<Exercise> exercises;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<ExerciseId> onAddExercise;
  final ValueChanged<ExerciseId> onViewExercise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: <Widget>[
          Material(
            color: SmartTrainnerColors.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              key: Key(
                'training_custom_exercise_group_${_muscleGroupTag(group)}',
              ),
              borderRadius: BorderRadius.circular(8),
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: SmartTrainnerColors.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      expanded ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${group.displayName} (${exercises.length})',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            for (final exercise in exercises)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  color: SmartTrainnerColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    key: Key(
                      'training_custom_add_exercise_${exercise.id.value}',
                    ),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onAddExercise(exercise.id),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: SmartTrainnerColors.line),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.add, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  exercise.targetText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SmartTrainnerColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            key: Key(
                              'training_custom_view_exercise_${exercise.id.value}',
                            ),
                            onPressed: () => onViewExercise(exercise.id),
                            icon: const Icon(Icons.info, size: 16),
                            label: const Text('운동 방법'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: '닫기',
          ),
        ],
      ),
    );
  }
}

class _DialogSectionTitle extends StatelessWidget {
  const _DialogSectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: SmartTrainnerColors.ink,
      ),
    );
  }
}

class _RoutineOptionPreview extends StatelessWidget {
  const _RoutineOptionPreview({
    required this.title,
    required this.options,
    required this.selectedIndex,
  });

  final String title;
  final List<String> options;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.indexed.map((entry) {
            final index = entry.$1;
            final label = entry.$2;
            return ChoiceChip(
              label: Text(label),
              selected: index == selectedIndex,
              onSelected: (_) {},
            );
          }).toList(),
        ),
      ],
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
        color: SmartTrainnerColors.surface,
        border: Border.all(color: SmartTrainnerColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          _ExerciseThumb(exercise: planned.exercise, width: 78, height: 86),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  planned.exercise.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                _MetricCluster(
                  label: '추천',
                  metrics: _plannedMetricBadges(planned),
                  maxItemsPerRow: 2,
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
    required this.onRestChanged,
    required this.onRemove,
  });

  final int index;
  final PlannedExercise planned;
  final RecordSetFormState entry;
  final ValueChanged<String> onRepsChanged;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<String> onRestChanged;
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
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: Key('training_set_rest_input_$index'),
              initialValue: entry.restSeconds,
              decoration: const InputDecoration(
                labelText: '휴식',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: onRestChanged,
            ),
          ),
        ] else ...<Widget>[
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
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: Key('training_set_rest_input_$index'),
              initialValue: entry.restSeconds,
              decoration: const InputDecoration(
                labelText: '휴식',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: onRestChanged,
            ),
          ),
        ],
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: '세트 제거',
        ),
      ],
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

class _NextRoutineDayCard extends StatelessWidget {
  const _NextRoutineDayCard({
    required this.template,
    required this.day,
    required this.completedIds,
    required this.onStartWorkout,
    required this.onCompleteDay,
  });

  final PlanTemplate template;
  final WorkoutDayPlan day;
  final Set<PlannedExerciseId> completedIds;
  final VoidCallback onStartWorkout;
  final VoidCallback onCompleteDay;

  @override
  Widget build(BuildContext context) {
    final sourceIsCustom = template.source == RoutineSource.custom;
    final focusItems = _distinctFocuses(<RoutineFocus>[
      if (day.primaryFocus != null) day.primaryFocus!,
      ...day.secondaryFocuses,
    ]);
    final completedCount = day.exercises
        .where((exercise) => completedIds.contains(exercise.id))
        .length;
    final progress = day.exercises.isEmpty
        ? 0.0
        : completedCount / day.exercises.length;
    return Container(
      key: const Key('training_next_routine_day_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SmartTrainnerColors.surfaceRaised,
        border: Border.all(color: SmartTrainnerColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _Badge(
                key: sourceIsCustom
                    ? const Key('training_home_routine_source_custom')
                    : null,
                label: sourceIsCustom ? '사용자 루틴' : '앱 기본 루틴',
                icon: Icons.fitness_center,
                backgroundColor: SmartTrainnerColors.coralSoft,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  template.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SmartTrainnerColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _routineTodayTitle(day),
            key: Key('training_next_routine_day_${day.dayNumber}'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: SmartTrainnerColors.ink,
            ),
          ),
          if (!sourceIsCustom) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              _routineDaySubtitle(day, template),
              key: const Key('training_next_routine_time_estimate'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: SmartTrainnerColors.coral,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SmartTrainnerProgressBar(progress: progress),
          const SizedBox(height: 12),
          _WidgetRows(
            key: const Key('training_next_routine_badges'),
            spacing: 8,
            runSpacing: 8,
            maxItemsPerRow: 2,
            children: <Widget>[
              if (!sourceIsCustom)
                _Badge(
                  key: const Key('training_next_routine_badge_duration'),
                  icon: Icons.timer,
                  label: '약 ${template.sessionMinutes}분',
                  backgroundColor: SmartTrainnerColors.coralSoft,
                ),
              _Badge(
                key: const Key('training_next_routine_badge_exercises'),
                icon: Icons.fitness_center,
                label: '운동 ${day.exercises.length}개',
                backgroundColor: SmartTrainnerColors.greenSoft,
              ),
              _Badge(
                key: const Key('training_next_routine_badge_recovery'),
                icon: Icons.calendar_month,
                label: '회복 ${day.minRecoveryHours}시간',
                backgroundColor: SmartTrainnerColors.amberSoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '루틴 진행: ${day.exercises.length}개 중 $completedCount개 기록',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: SmartTrainnerColors.muted),
          ),
          if (focusItems.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Text(
              '주요 부위',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: SmartTrainnerColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            _WidgetRows(
              key: const Key('training_next_routine_focus_section'),
              spacing: 8,
              runSpacing: 8,
              maxItemsPerRow: 4,
              children: focusItems.map((focus) {
                return _Badge(
                  key: Key(
                    'training_next_routine_focus_${_routineFocusTag(focus)}',
                  ),
                  label: _routineFocusShortLabel(focus),
                  backgroundColor: SmartTrainnerColors.coralSoft,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            '오늘 운동 계획',
            key: const Key('training_next_routine_plan_title'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: SmartTrainnerColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day.exercises.map((planned) => planned.exercise.name).join(' · '),
            key: const Key('training_next_routine_plan_exercises'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: SmartTrainnerColors.muted),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('training_home_start_workout'),
            onPressed: onStartWorkout,
            icon: const Icon(Icons.timer),
            label: const Text('운동 시작'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('training_complete_routine_day'),
            onPressed: onCompleteDay,
            icon: const Icon(Icons.check_circle),
            label: const Text('오늘 운동 완료'),
          ),
          const SizedBox(height: 12),
          Text(
            '다음 운동: ${_nextRoutineLabel(template, day)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: SmartTrainnerColors.muted),
          ),
        ],
      ),
    );
  }
}

class _CurrentRoutineCard extends StatelessWidget {
  const _CurrentRoutineCard({
    required this.template,
    required this.onEditCustom,
  });

  final PlanTemplate template;
  final VoidCallback? onEditCustom;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('training_current_routine_card'),
      decoration: BoxDecoration(
        color: SmartTrainnerColors.surfaceRaised,
        border: Border.all(color: SmartTrainnerColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  template.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _Badge(
                key: template.source == RoutineSource.custom
                    ? const Key('training_current_routine_source_custom')
                    : const Key('training_current_routine_source_default'),
                label: template.source == RoutineSource.custom
                    ? '사용자 루틴'
                    : '앱 기본 루틴',
                icon: template.source == RoutineSource.custom
                    ? Icons.edit
                    : Icons.fitness_center,
                backgroundColor: template.source == RoutineSource.custom
                    ? SmartTrainnerColors.greenSoft
                    : SmartTrainnerColors.coralSoft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RoutineTemplateBadges(template: template),
          const SizedBox(height: 8),
          _RoutineFlow(template: template),
          if (onEditCustom != null) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('training_edit_current_custom_routine'),
              onPressed: onEditCustom,
              icon: const Icon(Icons.edit),
              label: const Text('수정'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineFlow extends StatelessWidget {
  const _RoutineFlow({required this.template});

  final PlanTemplate template;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: Key('training_routine_flow_${template.id}'),
      spacing: 8,
      runSpacing: 8,
      children: template.days.map((day) {
        return Chip(
          key: Key('training_routine_flow_${template.id}_day_${day.dayNumber}'),
          label: Text('Day ${day.dayNumber}'),
        );
      }).toList(),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.icon,
    this.backgroundColor = SmartTrainnerColors.steelSoft,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14, color: SmartTrainnerColors.ink),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SmartTrainnerColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetRows extends StatelessWidget {
  const _WidgetRows({
    required this.children,
    required this.maxItemsPerRow,
    this.spacing = 0,
    this.runSpacing = 0,
    super.key,
  });

  final List<Widget> children;
  final int maxItemsPerRow;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < children.length; index += maxItemsPerRow) {
      final rowChildren = children
          .skip(index)
          .take(maxItemsPerRow)
          .toList(growable: false);
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final entry in rowChildren.indexed) ...<Widget>[
              if (entry.$1 > 0) SizedBox(width: spacing),
              entry.$2,
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final entry in rows.indexed) ...<Widget>[
          if (entry.$1 > 0) SizedBox(height: runSpacing),
          entry.$2,
        ],
      ],
    );
  }
}

class _MetricCluster extends StatelessWidget {
  const _MetricCluster({
    required this.label,
    required this.metrics,
    required this.maxItemsPerRow,
  });

  final String label;
  final List<_MetricBadgeData> metrics;
  final int maxItemsPerRow;

  @override
  Widget build(BuildContext context) {
    final tokens = <Widget>[
      _MetricToken(
        label: label,
        backgroundColor: SmartTrainnerColors.coralSoft,
        fontWeight: FontWeight.w800,
      ),
      ...metrics.map(
        (metric) => _MetricToken(
          label: metric.label,
          icon: metric.icon,
          backgroundColor: metric.backgroundColor.withValues(alpha: 0.56),
        ),
      ),
    ];
    return Wrap(spacing: 5, runSpacing: 5, children: tokens);
  }
}

class _MetricToken extends StatelessWidget {
  const _MetricToken({
    required this.label,
    this.icon,
    this.backgroundColor = SmartTrainnerColors.steelSoft,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 12, color: SmartTrainnerColors.ink),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SmartTrainnerColors.ink,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBadgeData {
  const _MetricBadgeData({
    required this.label,
    this.icon,
    this.backgroundColor = SmartTrainnerColors.steelSoft,
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
}

class _RoutineTemplateBadges extends StatelessWidget {
  const _RoutineTemplateBadges({required this.template});

  final PlanTemplate template;

  @override
  Widget build(BuildContext context) {
    final badges = template.source == RoutineSource.custom
        ? <Widget>[
            _Badge(
              label: '${template.days.length}일 구성',
              icon: Icons.calendar_month,
              backgroundColor: SmartTrainnerColors.greenSoft,
            ),
          ]
        : <Widget>[
            _Badge(label: template.level.displayName),
            _Badge(
              label: '주 ${template.daysPerWeek}일',
              icon: Icons.calendar_month,
              backgroundColor: SmartTrainnerColors.greenSoft,
            ),
            _Badge(
              label: '${template.sessionMinutes}분',
              icon: Icons.timer,
              backgroundColor: SmartTrainnerColors.coralSoft,
            ),
          ];
    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }
}

List<RoutineFocus> _distinctFocuses(List<RoutineFocus> focuses) {
  final seen = <RoutineFocus>{};
  return <RoutineFocus>[
    for (final focus in focuses)
      if (seen.add(focus)) focus,
  ];
}

String _routineTodayTitle(WorkoutDayPlan day) {
  final focus = day.primaryFocus;
  if (focus != null) {
    return '오늘은 ${_routineFocusShortLabel(focus)} 루틴';
  }
  final title = day.title.trim();
  if (title.isNotEmpty && !title.startsWith('Day ')) {
    return title;
  }
  return '오늘의 루틴';
}

String _routineDaySubtitle(WorkoutDayPlan day, PlanTemplate template) {
  final focusText = day.focus.trim();
  final middle = focusText.isEmpty ? day.title : focusText;
  return '${day.dayNumber}일차 · $middle · 약 ${template.sessionMinutes}분';
}

String _nextRoutineLabel(PlanTemplate template, WorkoutDayPlan currentDay) {
  if (template.days.isEmpty) {
    return '다음 루틴';
  }
  final index = template.days.indexWhere(
    (day) => day.dayNumber == currentDay.dayNumber,
  );
  final nextIndex = index < 0 ? 0 : (index + 1) % template.days.length;
  final nextDay = template.days[nextIndex];
  final focus = nextDay.primaryFocus;
  if (focus != null) {
    return '${_routineFocusShortLabel(focus)} 루틴';
  }
  return nextDay.title.trim().isEmpty ? '다음 루틴' : nextDay.title;
}

String _routineStructureLabel(RoutineStructure structure) {
  return switch (structure) {
    RoutineStructure.fullBody => '전신 루틴',
    RoutineStructure.balancedSplit => '균형 분할',
    RoutineStructure.bodyPartSplit => '부위 집중 루틴',
  };
}

String _routineFocusShortLabel(RoutineFocus focus) {
  return switch (focus) {
    RoutineFocus.fullBody => '전신',
    RoutineFocus.upperBody => '상체',
    RoutineFocus.push => '밀기',
    RoutineFocus.pull => '당기기',
    RoutineFocus.chest => '가슴',
    RoutineFocus.back => '등',
    RoutineFocus.lowerBody => '하체',
    RoutineFocus.shoulders => '어깨',
    RoutineFocus.arms => '팔',
    RoutineFocus.biceps => '이두',
    RoutineFocus.triceps => '삼두',
    RoutineFocus.forearms => '전완근',
    RoutineFocus.cardioConditioning => '유산소',
    RoutineFocus.core => '코어',
  };
}

List<_MetricBadgeData> _plannedMetricBadges(PlannedExercise planned) {
  final reps = planned.repRange;
  return <_MetricBadgeData>[
    _MetricBadgeData(
      label: '${planned.sets}세트',
      icon: Icons.fitness_center,
      backgroundColor: SmartTrainnerColors.greenSoft,
    ),
    if (reps != null)
      _MetricBadgeData(
        label: '${reps.first}-${reps.last}회',
        backgroundColor: SmartTrainnerColors.coralSoft,
      )
    else
      _MetricBadgeData(
        label: '${planned.durationMinutes ?? 10}분',
        icon: Icons.timer,
        backgroundColor: SmartTrainnerColors.amberSoft,
      ),
    _MetricBadgeData(
      label: '${planned.restSeconds}초',
      icon: Icons.timer,
      backgroundColor: SmartTrainnerColors.steelSoft,
    ),
  ];
}

List<_MetricBadgeData> _exerciseMetricBadges(Exercise exercise) {
  final reps = exercise.defaultRepRange;
  return <_MetricBadgeData>[
    _MetricBadgeData(
      label: '${exercise.defaultSets}세트',
      icon: Icons.fitness_center,
      backgroundColor: SmartTrainnerColors.greenSoft,
    ),
    if (reps != null)
      _MetricBadgeData(
        label: '${reps.first}-${reps.last}회',
        backgroundColor: SmartTrainnerColors.coralSoft,
      )
    else
      _MetricBadgeData(
        label: '${exercise.defaultDurationMinutes ?? 10}분',
        icon: Icons.timer,
        backgroundColor: SmartTrainnerColors.amberSoft,
      ),
    _MetricBadgeData(
      label: '${exercise.restSeconds}초',
      icon: Icons.timer,
      backgroundColor: SmartTrainnerColors.steelSoft,
    ),
  ];
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
      color: selected
          ? SmartTrainnerColors.coralSoft
          : SmartTrainnerColors.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('training_plan_exercise_${planned.exercise.id.value}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: SmartTrainnerColors.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _ExerciseThumb(exercise: planned.exercise, width: 76, height: 84),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      planned.exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 7),
                    _MetricCluster(
                      label: '추천',
                      metrics: _plannedMetricBadges(planned),
                      maxItemsPerRow: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (completed)
                const Icon(Icons.check_circle, color: SmartTrainnerColors.green)
              else
                OutlinedButton.icon(
                  key: const Key('training_plan_record_button'),
                  onPressed: onTap,
                  icon: const Icon(Icons.timer, size: 16),
                  label: const Text('기록'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(86, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: const BorderSide(color: SmartTrainnerColors.coral),
                  ),
                ),
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
    return Material(
      color: SmartTrainnerColors.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('training_exercise_row_${exercise.id.value}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: SmartTrainnerColors.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _ExerciseThumb(exercise: exercise, width: 76, height: 84),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            exercise.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Badge(
                          label: exercise.equipment.displayName,
                          backgroundColor: SmartTrainnerColors.steelSoft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _MetricCluster(
                      label: '추천',
                      metrics: _exerciseMetricBadges(exercise),
                      maxItemsPerRow: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  const _ExerciseThumb({
    required this.exercise,
    this.width = 58,
    this.height = 58,
  });

  final Exercise exercise;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: _ExerciseImage(exercise: exercise, fit: BoxFit.cover),
      ),
    );
  }
}

class _ExerciseImage extends StatelessWidget {
  const _ExerciseImage({required this.exercise, required this.fit});

  final Exercise exercise;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final assetPath = exerciseThumbnailAssetPath(exercise.id.value);
    if (assetPath == null) {
      return ColoredBox(
        color: SmartTrainnerColors.coralSoft,
        child: Center(
          child: Text(
            exercise.name.isEmpty ? '?' : exercise.name.substring(0, 1),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
    }
    return Image.asset(
      assetPath,
      package: 'smart_trainner_feature_training_impl',
      fit: fit,
    );
  }
}

class _ExerciseMetaChips extends StatelessWidget {
  const _ExerciseMetaChips({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _Badge(label: exercise.muscleGroup.displayName),
        _Badge(label: exercise.equipment.displayName),
        _Badge(label: exercise.difficulty.displayName),
      ],
    );
  }
}

class _StepImageSection extends StatelessWidget {
  const _StepImageSection({
    required this.exercise,
    required this.visuals,
    required this.steps,
    required this.onStepImageTap,
  });

  final Exercise exercise;
  final List<ExerciseStepVisual> visuals;
  final List<_LocalizedExerciseStep> steps;
  final void Function(Exercise exercise, int stepIndex) onStepImageTap;

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
            onImageTap: () => onStepImageTap(exercise, index),
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
    required this.onImageTap,
  });

  final int index;
  final Exercise exercise;
  final _LocalizedExerciseStep step;
  final ExerciseStepVisual? visual;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    final visual = this.visual;
    return _Surface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            key: Key('training_step_image_$index'),
            onTap: onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SmartTrainnerColors.surfaceRaised,
        border: Border.all(color: SmartTrainnerColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '이번 주 요약',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: SmartTrainnerColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricTile(
                  label: '완료율',
                  value: '${summary?.completionRate ?? 0}%',
                  accent: SmartTrainnerColors.coral,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: '총 세트',
                  value: '${summary?.totalSets ?? 0}',
                  accent: SmartTrainnerColors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: '연속',
                  value: '${summary?.streakDays ?? 0}일',
                  accent: SmartTrainnerColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary?.insight ?? '첫 기록을 저장하면 분석이 시작됩니다.',
            style: const TextStyle(color: SmartTrainnerColors.ink),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: accent,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RecentRecordsCard extends StatelessWidget {
  const _RecentRecordsCard({required this.logs, required this.plan});

  final List<WorkoutLog> logs;
  final WeeklyPlan? plan;

  @override
  Widget build(BuildContext context) {
    final records = logs.take(3).toList();
    return _Surface(
      key: const Key('training_recent_records_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '최근 기록',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SmartTrainnerColors.ink,
                  ),
                ),
              ),
              _Badge(
                key: const Key('training_recent_records_count'),
                label: '최근 ${records.length}개',
                backgroundColor: SmartTrainnerColors.coralSoft,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...records.map((log) {
            final planned = plan?.findPlannedExercise(log.plannedExerciseId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentRecordItem(log: log, plannedExercise: planned),
            );
          }),
        ],
      ),
    );
  }
}

class _RecentRecordItem extends StatelessWidget {
  const _RecentRecordItem({required this.log, required this.plannedExercise});

  final WorkoutLog log;
  final PlannedExercise? plannedExercise;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  plannedExercise?.exercise.name ?? log.exerciseId.value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _Badge(
                label: '${log.performedAt.month}월 ${log.performedAt.day}일',
                backgroundColor: SmartTrainnerColors.steelSoft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Badge(label: '세트 ${log.sets}개'),
              if (log.reps != null) _Badge(label: '반복 ${log.reps}회'),
              if (log.weightKg != null)
                _Badge(label: '${log.weightKg!.toStringAsFixed(1)}kg'),
              if (log.durationMinutes != null)
                _Badge(label: '운동 ${log.durationMinutes}분'),
            ],
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
    final maxMuscleBalance = summary.muscleBalance.values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '부위별 완료',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: SmartTrainnerColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (summary.muscleBalance.isEmpty)
            const Text(
              '아직 기록이 없습니다. 오늘 운동을 마치면 바로 변화가 보입니다.',
              style: TextStyle(color: SmartTrainnerColors.muted),
            )
          else ...<Widget>[
            for (final entry in summary.muscleBalance.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            entry.key.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${entry.value}회',
                          style: const TextStyle(
                            color: SmartTrainnerColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SmartTrainnerProgressBar(
                      progress: entry.value / maxMuscleBalance,
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SmartTrainnerColors.amberSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                summary.insight,
                style: const TextStyle(color: SmartTrainnerColors.ink),
              ),
            ),
          ],
        ],
      ),
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
  const _Surface({required this.child, super.key});

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
    RecordFormError.rest => '휴식은 0초 이상 600초 이하로 입력해 주세요.',
    RecordFormError.saveFailed => '기록 저장에 실패했습니다.',
  };
}

WorkoutDayPlan? _currentRoutineDayPlan(TrainingUiState state) {
  final plan = _activeRoutinePlan(state);
  if (plan == null) {
    return null;
  }
  final index = state.activeRoutineDayIndex
      .clamp(0, plan.days.length - 1)
      .toInt();
  return plan.days[index];
}

WeeklyPlan? _activeRoutinePlan(TrainingUiState state) {
  final template = state.activeRoutineTemplate;
  if (template == null || template.days.isEmpty) {
    return null;
  }
  final plan = state.plan;
  if (plan?.templateId == template.id) {
    return plan;
  }
  final weekStart = plan?.weekStartDate ?? _mondayOf(DateTime.now());
  final exercisesById = <ExerciseId, Exercise>{
    for (final exercise in state.exercises) exercise.id: exercise,
  };
  return WeeklyPlan(
    id: PlanId('${template.id}_${weekStart.dateKey}'),
    templateId: template.id,
    name: template.name,
    weekStartDate: weekStart,
    days: template.days.map((templateDay) {
      final date = weekStart.add(Duration(days: templateDay.dayOffset));
      return WorkoutDayPlan(
        date: date,
        title: templateDay.title,
        focus: templateDay.focus,
        dayNumber: templateDay.dayNumber,
        primaryFocus: templateDay.primaryFocus,
        secondaryFocuses: templateDay.secondaryFocuses,
        minRecoveryHours: templateDay.minRecoveryHours,
        exercises: templateDay.exercises.indexed
            .map((entry) {
              final slotIndex = entry.$1;
              final item = entry.$2;
              final exercise = exercisesById[item.exerciseId];
              if (exercise == null) {
                return null;
              }
              return PlannedExercise(
                id: PlannedExerciseId(
                  _plannedExerciseId(
                    template: template,
                    date: date,
                    dayNumber: templateDay.dayNumber,
                    slotIndex: slotIndex,
                    exerciseId: item.exerciseId,
                  ),
                ),
                exercise: exercise,
                sets: item.sets,
                repRange: item.repRange,
                durationMinutes: item.durationMinutes,
                restSeconds: item.restSeconds,
                note: item.note,
              );
            })
            .whereType<PlannedExercise>()
            .toList(),
      );
    }).toList(),
  );
}

DateTime _mondayOf(DateTime date) {
  final normalized = normalizeDate(date);
  return normalized.subtract(
    Duration(days: normalized.weekday - DateTime.monday),
  );
}

String _plannedExerciseId({
  required PlanTemplate template,
  required DateTime date,
  required int dayNumber,
  required int slotIndex,
  required ExerciseId exerciseId,
}) {
  if (template.source == RoutineSource.custom) {
    return '${date.dateKey}_${template.id}_day${dayNumber}_slot${slotIndex + 1}_${exerciseId.value}';
  }
  return '${date.dateKey}_${exerciseId.value}';
}

extension _TrainingRouteDateKey on DateTime {
  String get dateKey {
    final normalized = normalizeDate(this);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}

const _customFocusOptions = <RoutineFocus>[
  RoutineFocus.upperBody,
  RoutineFocus.push,
  RoutineFocus.pull,
  RoutineFocus.chest,
  RoutineFocus.back,
  RoutineFocus.lowerBody,
  RoutineFocus.shoulders,
  RoutineFocus.arms,
  RoutineFocus.biceps,
  RoutineFocus.triceps,
  RoutineFocus.forearms,
  RoutineFocus.core,
  RoutineFocus.cardioConditioning,
];

Set<MuscleGroup> _allowedCustomRoutineMuscleGroups(RoutineFocus? focus) {
  return switch (focus) {
    null || RoutineFocus.fullBody => MuscleGroup.values.toSet(),
    RoutineFocus.upperBody => {
      MuscleGroup.back,
      MuscleGroup.chest,
      MuscleGroup.shoulders,
      MuscleGroup.arms,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
      MuscleGroup.forearms,
    },
    RoutineFocus.push => {
      MuscleGroup.chest,
      MuscleGroup.shoulders,
      MuscleGroup.triceps,
    },
    RoutineFocus.pull => {
      MuscleGroup.back,
      MuscleGroup.biceps,
      MuscleGroup.forearms,
    },
    RoutineFocus.chest => {MuscleGroup.chest},
    RoutineFocus.back => {MuscleGroup.back},
    RoutineFocus.lowerBody => {MuscleGroup.lowerBody},
    RoutineFocus.shoulders => {MuscleGroup.shoulders},
    RoutineFocus.arms => {
      MuscleGroup.arms,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
      MuscleGroup.forearms,
    },
    RoutineFocus.biceps => {MuscleGroup.biceps},
    RoutineFocus.triceps => {MuscleGroup.triceps},
    RoutineFocus.forearms => {MuscleGroup.forearms},
    RoutineFocus.cardioConditioning => {MuscleGroup.cardio},
    RoutineFocus.core => {MuscleGroup.core},
  };
}

String _muscleGroupTag(MuscleGroup group) {
  return switch (group) {
    MuscleGroup.lowerBody => 'LOWER_BODY',
    MuscleGroup.back => 'BACK',
    MuscleGroup.chest => 'CHEST',
    MuscleGroup.shoulders => 'SHOULDERS',
    MuscleGroup.arms => 'ARMS',
    MuscleGroup.biceps => 'BICEPS',
    MuscleGroup.triceps => 'TRICEPS',
    MuscleGroup.forearms => 'FOREARMS',
    MuscleGroup.core => 'CORE',
    MuscleGroup.cardio => 'CARDIO',
    MuscleGroup.fullBody => 'FULL_BODY',
  };
}

String _routineFocusTag(RoutineFocus focus) {
  return switch (focus) {
    RoutineFocus.fullBody => 'FULL_BODY',
    RoutineFocus.upperBody => 'UPPER_BODY',
    RoutineFocus.push => 'PUSH',
    RoutineFocus.pull => 'PULL',
    RoutineFocus.chest => 'CHEST',
    RoutineFocus.back => 'BACK',
    RoutineFocus.lowerBody => 'LOWER_BODY',
    RoutineFocus.shoulders => 'SHOULDERS',
    RoutineFocus.arms => 'ARMS',
    RoutineFocus.biceps => 'BICEPS',
    RoutineFocus.triceps => 'TRICEPS',
    RoutineFocus.forearms => 'FOREARMS',
    RoutineFocus.cardioConditioning => 'CARDIO_CONDITIONING',
    RoutineFocus.core => 'CORE',
  };
}

extension _ChunkedList<T> on List<T> {
  Iterable<List<T>> chunked(int size) sync* {
    for (var start = 0; start < length; start += size) {
      final end = (start + size).clamp(0, length).toInt();
      yield sublist(start, end);
    }
  }
}

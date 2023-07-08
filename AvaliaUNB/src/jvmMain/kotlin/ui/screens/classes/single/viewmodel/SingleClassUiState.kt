package ui.screens.classes.single.viewmodel

import data.models.ClassModel
import data.models.TeacherModel

data class SingleClassUiState(
    val classModel: ClassModel,
    val teacherModel: TeacherModel
)
package data.source

import data.models.ClassReviewModel
import javax.inject.Inject
import javax.inject.Singleton
import javax.swing.text.StyledEditorKit.BoldAction

@Singleton
class ReviewDAO @Inject constructor(
    private val database: DatabaseManager
) {
    fun insertClassReview(reviewModel: ClassReviewModel) {
        val reviewInsertStatement = "INSERT INTO avaliacao (comentario, pontuacao, matricula_aluno) " +
                "VALUES (?, ?, ?)"

        val reviewPreparedStatement = database.prepareStatement(reviewInsertStatement)

        reviewModel.apply {
            reviewPreparedStatement.setString(1, comment)
            reviewPreparedStatement.setInt(2, rating)
            reviewPreparedStatement.setString(3, userRegistrationNumber)
        }

        reviewPreparedStatement.execute()

        val classReviewInsertStatement = "INSERT INTO avaliacao_turma (id_avaliacao, id_turma) " +
                "VALUES (?, ?)"

        val classReviewPreparedStatement = database.prepareStatement(classReviewInsertStatement)

        val generatedKeys = reviewPreparedStatement.generatedKeys
        generatedKeys.next()

        reviewModel.apply {
            classReviewPreparedStatement.setInt(1, generatedKeys.getInt(1))
            classReviewPreparedStatement.setInt(2, classId)
        }

        classReviewPreparedStatement.execute()
    }

    fun userMadeReview(userRegistrationNumber: String, classId: Int): Boolean {
        val reviewQueryResult = database.executeQuery(
            "SELECT * FROM avaliacao " +
                    "INNER JOIN avaliacao_turma ON avaliacao.id = avaliacao_turma.id_avaliacao " +
                    "WHERE avaliacao_turma.id_turma = $classId AND avaliacao.matricula_aluno = $userRegistrationNumber"
        )

        return reviewQueryResult.next()
    }

    /*
    fun insertTeacherReview(reviewModel: ) {

    }*/
}
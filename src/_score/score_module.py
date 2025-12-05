from scoring.module import ScoreModule


class SurveyWidget(ScoreModule):

    def check_answer(self, log):
        if log.get("text") is not None and log.get("text") != "":
            return 100
        return 0

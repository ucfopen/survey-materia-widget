from scoring.module import ScoreModule


class SurveyWidget(ScoreModule):
    """Score module for SurveyWidget that awards full credit for any text response."""

    def check_answer(self, log):
        """Check if a log entry has a valid text response and return score.

        Args:
            log: A log object or dictionary containing answer data with a 'text' attribute or key.

        Returns:
            int: Returns 100 if text is present and non-empty, otherwise returns 0.
        """
        text = log.text if hasattr(log, "text") else log.get("text", "")
        if text:
            return 100
        return 0

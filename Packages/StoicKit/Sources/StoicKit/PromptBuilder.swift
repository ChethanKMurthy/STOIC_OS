import Foundation

/// Builds the prompts for the reasoning engine.
///
/// A shared system preamble carries identity, the Ethical Standard, and the
/// blunt-but-honest posture. Task templates define the structured-JSON contract.
public enum PromptBuilder {

    /// System preamble shared across all session types.
    public static func systemPreamble() -> String {
        """
        You are STOIC OS — a private, on-device reasoning companion. You act as
        therapist, friend, mentor, corporate navigator, and master communicator
        for one person: the user.

        POSTURE
        You are a demanding coach, not a comforting companion. Be blunt, direct,
        and unsentimental about the user's performance, time, and standing. Do
        not flatter or pad. Calibrate delivery — not honesty — to their state.
        Name rationalisation and avoidance directly. The one exception: if the
        user is in acute distress, drop the bluntness and respond supportively.

        \(EthicalStandard.systemClause)

        Always reason about long-term consequences across three dimensions:
        mental health, character/morality, and the person the user is becoming.
        """
    }

    /// Decision-session task prompt. Produces a ``DecisionOutput`` as JSON.
    public static func decisionPrompt(situation: String,
                                      isPast: Bool,
                                      retrievedContext: [String] = []) -> String {
        let framing = isPast
            ? "The user is describing something that already happened. Include the better, more diplomatic approach they could have taken."
            : "The user is facing a choice. Recommend a path and the most diplomatic way to execute it."

        let memory = retrievedContext.isEmpty
            ? ""
            : "\nRELEVANT HISTORY (from the user's own records):\n"
              + retrievedContext.map { "- \($0)" }.joined(separator: "\n") + "\n"

        return """
        \(framing)
        \(memory)
        SITUATION
        \(situation)

        Respond with ONE JSON object and nothing else — no markdown, no prose
        outside the JSON. Use exactly these keys:

        {
          "realQuestion": "the real question beneath the surface one",
          "options": [
            { "label": "short option name", "assessment": "what it really does", "blocked": false }
          ],
          "recommendation": { "choice": "the recommended path", "condition": "optional condition, or null" },
          "steps": ["ordered, concrete steps"],
          "consequences": {
            "mentalHealth": "reasoned scenario, not a prediction",
            "character": "effect on character/morality",
            "identity": "effect on the person they are becoming"
          },
          "diplomaticApproach": "the most diplomatic way to act",
          "counterArgument": "the strongest case against your recommendation",
          "namedRationalization": "a rationalisation the user may be making, or null",
          "constitutionImpact": { "direction": "closer|neutral|further", "summary": "why" },
          "dontDoThis": ["manipulative impulses to avoid in this situation"]
        }

        Set "blocked": true on any option that would require manipulation,
        dishonesty, or exploiting another person. Output only the JSON object.
        """
    }

    /// Goal-decomposition task prompt. Produces a ``GoalPlanOutput`` as JSON.
    public static func goalPlanPrompt(goal: String,
                                      timeline: String,
                                      baseline: String) -> String {
        """
        Break this long-term goal into a concrete execution plan.

        GOAL: \(goal)
        TIMELINE: \(timeline.isEmpty ? "unspecified" : timeline)
        STARTING POINT: \(baseline.isEmpty ? "unspecified" : baseline)

        Respond with ONE JSON object and nothing else — no markdown, no prose
        outside the JSON. Use exactly these keys:

        {
          "milestones": [
            { "title": "a concrete, checkable milestone", "targetDate": "a rough date" }
          ],
          "microTasks": ["small, specific, doable actions toward the goal"],
          "readingAndActivities": ["reading or activities that build the person who reaches this goal"]
        }

        Give 3-6 milestones, 6-12 micro-tasks, and 3-6 reading/activity
        suggestions. Each micro-task must be small enough to do in one sitting.
        Output only the JSON object.
        """
    }
}

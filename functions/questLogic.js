export const REWARD = Object.freeze({completed: true, points: 10, badgeId: 'first-quest'});
export function rewardDecision(existing) {
  return existing ? {completed: true, points: existing.points, badgeId: existing.badgeId, alreadyCompleted: true} : {...REWARD, alreadyCompleted: false};
}
export function questPaths(uid) {
  if (typeof uid !== 'string' || !uid.trim() || uid.includes('/')) throw new Error('Verified user ID required');
  return {challenge: 'challenges/today', progress: `users/${uid}/progress/today`};
}
export function validateQuestion(question) {
  if (typeof question !== 'string' || !question.trim() || question.length > 300) throw new Error('Question must be 1–300 characters');
  return question.trim();
}
export function safeHint(state) {
  const title = String(state.challenge?.title || 'today’s quest');
  const prompt = String(state.challenge?.prompt || 'Read the challenge carefully.');
  return state.progress?.completed
    ? `You already completed ${title}. Your First Quest badge is earned. No additional reward is available.`
    : `For ${title}, start by breaking this challenge into one small step: ${prompt} Think through the first action, then use Complete challenge when you are ready.`;
}

// Culinary helper functions for generating natural, diverse Russian recipes

function capitalize(s) {
  if (!s) return '';
  return s.charAt(0).toUpperCase() + s.slice(1);
}

// Generates unique step texts by varying sentence structure and vocabulary
function makeStep(text, timerSeconds, tip) {
  const step = { text: text.trim() };
  if (timerSeconds && timerSeconds > 0) {
    step.timer_seconds = timerSeconds;
  }
  if (tip && tip.trim().length > 0) {
    step.tip = tip.trim();
  }
  return step;
}

module.exports = {
  capitalize,
  makeStep
};

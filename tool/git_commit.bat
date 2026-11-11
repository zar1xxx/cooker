@echo off
chcp 65001 >nul
cd /d "%~dp0.."
set OUT=docs\reports\last_git.txt
(
git add .gitignore assets/seed/recipes.json tool/seed_data/rewrite tool/seed_data/priority_dishes.csv tool/py tool/r9_lib.dart tool/apply_rewrite_batch.dart tool/detect_templated_recipes.dart tool/lint_curated_recipes.dart tool/rank_rewrite_queue.dart tool/compile_catalog.dart tool/validate_seed.dart test/r9_pipeline_test.dart test/curated_recipes_lint_test.dart test/detect_templated_test.dart test/recipe_quality_test.dart docs/reports/rewrite docs/R10_PRODUCT_EXPANSION.md
git commit -F .tmp_msg1.txt
git add -A
git commit -F .tmp_msg2.txt
git status --short
git log --oneline -4
) > %OUT% 2>&1
exit

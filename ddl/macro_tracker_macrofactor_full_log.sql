CREATE OR REPLACE TABLE personal_data.nutrition.macro_tracker_macrofactor_full_log AS
FROM read_csv('https://docs.google.com/spreadsheets/d/1ntZTmB4F_j-Bpj3M6LSF8NjMNTZSoa4lE0EHyYaTYFY/export?format=csv&gid=45651593');

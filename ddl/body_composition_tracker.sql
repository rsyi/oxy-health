CREATE OR REPLACE TABLE personal_data.body.body_composition_tracker AS
FROM read_csv('https://docs.google.com/spreadsheets/d/1GfL65B3upDl188h28CwDSMJ8uhEXfG_fPPjdTES9f-I/export?format=csv&gid=859895118');


# PIH OpenMRS HTML Form documentation

The contents of this /documentation folder are .csv files to accompany the form configuration files in the parent directory.  
These CSVs should always be serialized as valid CSV (consistent column counts per row, and proper quoting/escaping for commas, quotes, and multiline values) so they render and remain searchable in GitHub.

To regenerate documenting HFE files as .CSVs like this:

Start a new Claude session and:

 - Upload parse_hfe.py, full_concept_mappings.csv (the latest one), and hfe-csv-docs.skill.md
 - Say something like "I need to generate documentation CSVs for another set of OpenMRS HFE XML forms — I've uploaded the parser, concept mappings, and skill doc from last time"

These files are in this directory. 

Note that the full_concept_mappings csv was generated from this SQL statement against OpenMRS:

 select concept_name(concept_id,'en') "name", r.* from report_mapping  r ;

 You may want to regenerate that to ensure the latest mappings are used.
 

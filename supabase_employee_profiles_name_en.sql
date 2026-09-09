-- Adds an optional English name for employee_profiles, used by the portal
-- to display the employee's name in English when the EN toggle is on.
-- Falls back to the (Arabic) `name` column when null/empty.
alter table employee_profiles add column if not exists name_en text;

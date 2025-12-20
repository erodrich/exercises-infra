-- Exercise Backend Seed Data
-- Version: 1.1.0
-- Description: Pre-populate database with muscle groups and common exercises
-- Updated: 2024-12-19 - Updated to use muscle_groups table and new table names

-- Note: This script is optional and typically used in development
-- For production, consider whether you want to pre-load data or allow users to create their own

-- First, insert muscle groups
INSERT INTO muscle_groups (id, name, description)
VALUES (1, 'Chest', 'Chest exercises for pectoral muscles');
INSERT INTO muscle_groups (id, name, description)
VALUES (2, 'Shoulders', 'Shoulder exercises for deltoid muscles');
INSERT INTO muscle_groups (id, name, description)
VALUES (3, 'Triceps', 'Tricep exercises for triceps brachii');
INSERT INTO muscle_groups (id, name, description)
VALUES (4, 'Back', 'Back exercises for latissimus dorsi and other back muscles');
INSERT INTO muscle_groups (id, name, description)
VALUES (5, 'Biceps', 'Bicep exercises for biceps brachii');
INSERT INTO muscle_groups (id, name, description)
VALUES (6, 'Legs', 'Leg exercises for quadriceps, hamstrings, and calves');

INSERT INTO exercises (id, name, muscle_group_id)
VALUES (1, 'Incline Dumbbell Press', 1);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (2, 'Dumbbell Flat Press', 1);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (3, 'Seated Overhead Press', 2);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (4, 'Dumbbell Lateral Raises', 2);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (5, 'Rope Pushdowns', 3);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (6, 'Overhead Dumbbell Triceps Extension', 3);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (7, 'Deadlift', 4);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (8, 'Barbell Rows', 4);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (9, 'Lat Pulldown', 4);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (10, 'Face Pulls', 2);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (11, 'Incline Dumbbell Curls', 5);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (12, 'Hammer Curls', 5);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (13, 'Squat on Smith (Machine)', 6);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (14, 'Leg Press', 6);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (15, 'Walking Lunges', 6);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (16, 'Incline Barbell Press', 1);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (17, 'Pec Deck Flies', 1);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (18, 'Seated Overhead Press (Machine)', 2);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (19, 'Cable Lateral Raises', 2);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (20, 'Dips', 3);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (21, 'Skull Crushers', 3);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (22, 'Seated Chest Press', 1);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (23, 'Dumbbell Rows', 4);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (24, 'Hack Squat (Machine)', 6);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (25, 'Leg Curl', 6);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (26, 'Arnold Press', 2);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (27, 'Dumbbell Skull Crushers', 3);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (28, 'Rack Pulls', 4);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (29, 'Chest-Supported Rows', 4);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (30, 'Chin-ups', 4);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (31, 'Cable Rear Delt Flies', 2);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (32, 'Concentration Curls', 5);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (33, 'Cable Rope Curls', 5);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (34, 'Barbell Bench Press', 1);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (35, 'Standing Calf Raises', 6);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (36, 'Cable Flies', 1);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (37, 'Dips (Machine)', 3);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (38, 'Cable Chin-Ups', 4);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (39, 'Dumbbell Rear Delt Flies', 2);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (40, 'Incline Dumbbell Flies', 1);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (41, 'Cable Triceps Pushdowns', 3);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (42, 'Overhead Rope Triceps Extension', 3);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (43, 'Lat Pulldown (Machine)', 4);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (44, 'Spider Hammer Curls', 5);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (45, 'Cable Incline Curl', 5);
INSERT INTO exercises (id, name, muscle_group_id)
VALUES (46, 'Dumbbell Flat Flies', 1);

-- Update the sequences to continue from the last inserted ID
SELECT setval('muscle_groups_seq', 10);
SELECT setval('exercises_seq', 50);

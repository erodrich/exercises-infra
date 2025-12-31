-- Workout Plan Feature Schema
-- Version: 1.0.0
-- Description: Tables for workout plan management with days and exercise targets
-- Created: 2024-12-31

-- Drop existing tables if they exist (reverse order for FK constraints)
DROP TABLE IF EXISTS exercise_target CASCADE;
DROP TABLE IF EXISTS workout_days CASCADE;
DROP TABLE IF EXISTS workout_plans CASCADE;

-- Drop sequences if they exist
DROP SEQUENCE IF EXISTS workout_plans_seq;
DROP SEQUENCE IF EXISTS workout_days_seq;
DROP SEQUENCE IF EXISTS exercise_target_seq;

-- Create sequences for primary keys (GenerationType.AUTO compatibility)
CREATE SEQUENCE workout_plans_seq START WITH 1 INCREMENT BY 50;
CREATE SEQUENCE workout_days_seq START WITH 1 INCREMENT BY 50;
CREATE SEQUENCE exercise_target_seq START WITH 1 INCREMENT BY 50;

-- Workout plans table
CREATE TABLE workout_plans (
    id BIGINT NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    duration INTEGER NOT NULL,
    duration_unit VARCHAR(20) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT false,
    user_id BIGINT NOT NULL,
    CONSTRAINT fk_workout_plans_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_duration_unit CHECK (duration_unit IN ('WEEKS', 'MONTHS')),
    CONSTRAINT chk_duration_positive CHECK (duration > 0)
);

-- Workout days table
CREATE TABLE workout_days (
    id BIGINT NOT NULL PRIMARY KEY,
    description VARCHAR(500) NOT NULL,
    workout_plan_id BIGINT NOT NULL,
    CONSTRAINT fk_workout_days_plan FOREIGN KEY (workout_plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE
);

-- Exercise target table
CREATE TABLE exercise_target (
    id BIGINT NOT NULL PRIMARY KEY,
    exercise_id BIGINT NOT NULL,
    sets INTEGER NOT NULL,
    min_reps INTEGER NOT NULL,
    max_reps INTEGER NOT NULL,
    workout_day_id BIGINT NOT NULL,
    CONSTRAINT fk_exercise_target_exercise FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE,
    CONSTRAINT fk_exercise_target_day FOREIGN KEY (workout_day_id) REFERENCES workout_days(id) ON DELETE CASCADE,
    CONSTRAINT chk_sets_positive CHECK (sets > 0),
    CONSTRAINT chk_reps_positive CHECK (min_reps > 0 AND max_reps > 0),
    CONSTRAINT chk_reps_range CHECK (max_reps >= min_reps)
);

-- Create indexes for workout_plans
CREATE INDEX idx_workout_plans_user ON workout_plans(user_id);
CREATE INDEX idx_workout_plans_active ON workout_plans(is_active);
CREATE INDEX idx_workout_plans_name ON workout_plans(name);

-- Create indexes for workout_days
CREATE INDEX idx_workout_days_plan ON workout_days(workout_plan_id);

-- Create indexes for exercise_target
CREATE INDEX idx_exercise_target_day ON exercise_target(workout_day_id);
CREATE INDEX idx_exercise_target_exercise ON exercise_target(exercise_id);

-- Comments for documentation
COMMENT ON TABLE workout_plans IS 'Workout plans created by users with duration and active status';
COMMENT ON COLUMN workout_plans.duration IS 'Duration of the workout plan';
COMMENT ON COLUMN workout_plans.duration_unit IS 'Unit of duration: WEEKS or MONTHS';
COMMENT ON COLUMN workout_plans.is_active IS 'Indicates if this is the users currently active workout plan';
COMMENT ON COLUMN workout_plans.user_id IS 'Owner of the workout plan';

COMMENT ON TABLE workout_days IS 'Individual days within a workout plan';
COMMENT ON COLUMN workout_days.description IS 'Description of the workout day (e.g., "Push Day", "Leg Day")';
COMMENT ON COLUMN workout_days.workout_plan_id IS 'Parent workout plan';

COMMENT ON TABLE exercise_target IS 'Exercise targets for each workout day';
COMMENT ON COLUMN exercise_target.sets IS 'Target number of sets';
COMMENT ON COLUMN exercise_target.min_reps IS 'Minimum target repetitions';
COMMENT ON COLUMN exercise_target.max_reps IS 'Maximum target repetitions';
COMMENT ON COLUMN exercise_target.workout_day_id IS 'Parent workout day';
COMMENT ON COLUMN exercise_target.exercise_id IS 'Reference to the exercise';

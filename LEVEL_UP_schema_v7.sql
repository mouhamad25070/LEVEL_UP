-- LEVEL UP — Schéma initial de base de données
-- Compatible PostgreSQL
-- Version 1.0

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================
-- 1. UTILISATEURS
-- =========================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash TEXT NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(20) NOT NULL DEFAULT 'student'
        CHECK (role IN ('student', 'teacher', 'admin')),
    avatar_url TEXT,
    total_xp INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
    level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- 2. PROGRAMMES / ANNÉES
-- =========================

CREATE TABLE academic_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'Côte d''Ivoire',
    education_level VARCHAR(100) NOT NULL,
    school_year VARCHAR(20),
    source_name TEXT,
    source_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- 3. CLASSES
-- =========================

CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID REFERENCES academic_programs(id) ON DELETE SET NULL,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    order_index INTEGER NOT NULL DEFAULT 0,
    UNIQUE(program_id, code)
);

-- =========================
-- 4. FILIÈRES
-- =========================

CREATE TABLE tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(50) NOT NULL
        CHECK (category IN ('general', 'technical', 'vocational')),
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Une classe peut proposer plusieurs filières.
CREATE TABLE class_tracks (
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    track_id UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
    PRIMARY KEY (class_id, track_id)
);

-- =========================
-- 5. MATIÈRES
-- =========================

CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Une matière peut appartenir à plusieurs classes/filières.
CREATE TABLE curriculum_subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    track_id UUID REFERENCES tracks(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    coefficient NUMERIC(5,2),
    is_core BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(class_id, track_id, subject_id)
);

-- =========================
-- 6. CHAPITRES ET LEÇONS
-- =========================

CREATE TABLE chapters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    curriculum_subject_id UUID NOT NULL
        REFERENCES curriculum_subjects(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    order_index INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    curriculum_version VARCHAR(50) NOT NULL DEFAULT 'standard',
    chapter_id UUID NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    summary TEXT,
    content TEXT,
    objectives TEXT,
    order_index INTEGER NOT NULL DEFAULT 0,
    estimated_minutes INTEGER,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- 7. EXERCICES
-- =========================

CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    title VARCHAR(200),
    statement TEXT NOT NULL,
    exercise_type VARCHAR(30) NOT NULL DEFAULT 'qcm'
        CHECK (exercise_type IN (
            'qcm',
            'true_false',
            'short_answer',
            'numeric',
            'calculation',
            'matching',
            'ordering',
            'code',
            'diagram'
        )),
    difficulty INTEGER NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    xp_reward INTEGER NOT NULL DEFAULT 20 CHECK (xp_reward >= 0),
    explanation TEXT,
    hint TEXT,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE exercise_choices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    choice_text TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    order_index INTEGER NOT NULL DEFAULT 0
);

-- =========================
-- 8. PROGRESSION DES ÉLÈVES
-- =========================

CREATE TABLE user_class_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    track_id UUID REFERENCES tracks(id) ON DELETE SET NULL,
    school_year VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'archived')),
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE lesson_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'started'
        CHECK (status IN ('locked', 'started', 'completed')),
    completion_percent INTEGER NOT NULL DEFAULT 0
        CHECK (completion_percent BETWEEN 0 AND 100),
    best_score INTEGER NOT NULL DEFAULT 0,
    completed_at TIMESTAMPTZ,
    UNIQUE(user_id, lesson_id)
);

CREATE TABLE exercise_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    answer TEXT,
    is_correct BOOLEAN NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    xp_earned INTEGER NOT NULL DEFAULT 0,
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- 9. XP / NIVEAUX
-- =========================

CREATE TABLE xp_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    source_type VARCHAR(50) NOT NULL,
    source_id UUID,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE level_definitions (
    level INTEGER PRIMARY KEY,
    required_total_xp INTEGER NOT NULL UNIQUE,
    title VARCHAR(100) NOT NULL
);

-- =========================
-- 10. BADGES
-- =========================

CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    code VARCHAR(80) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(50),
    requirement_type VARCHAR(50),
    requirement_value INTEGER
);

CREATE TABLE user_badges (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY(user_id, badge_id)
);

-- =========================
-- 11. MISSIONS
-- =========================

CREATE TABLE missions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    mission_type VARCHAR(50) NOT NULL,
    target_value INTEGER NOT NULL DEFAULT 1,
    xp_reward INTEGER NOT NULL DEFAULT 0,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE user_missions (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    progress INTEGER NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    PRIMARY KEY(user_id, mission_id)
);

-- =========================
-- 12. CLASSEMENT
-- =========================
-- Le classement peut être calculé à partir de users.total_xp.
-- Une table historique pourra être ajoutée plus tard si nécessaire.

-- =========================
-- 13. INDEX
-- =========================

CREATE INDEX idx_users_total_xp ON users(total_xp DESC);
CREATE INDEX idx_lessons_chapter_order ON lessons(chapter_id, order_index);
CREATE INDEX idx_exercises_lesson ON exercises(lesson_id);
CREATE INDEX idx_attempts_user ON exercise_attempts(user_id, attempted_at DESC);
CREATE INDEX idx_xp_user ON xp_transactions(user_id, created_at DESC);
CREATE INDEX idx_progress_user ON lesson_progress(user_id);
CREATE INDEX idx_classes_order ON classes(order_index);
CREATE INDEX idx_curriculum_subject_class ON curriculum_subjects(class_id, track_id);
CREATE INDEX idx_lessons_published ON lessons(is_published);

-- =========================
-- 14. NIVEAUX INITIAUX
-- =========================

INSERT INTO level_definitions(level, required_total_xp, title) VALUES
(1, 0, 'Débutant'),
(2, 100, 'Explorateur'),
(3, 250, 'Apprenti'),
(4, 450, 'Progression'),
(5, 700, 'Confirmé'),
(6, 1000, 'Expert'),
(7, 1400, 'Maître'),
(8, 1900, 'Élite'),
(9, 2500, 'Champion'),
(10, 3250, 'Légende');

-- =========================
-- 15. CLASSES DE DÉPART
-- 6e -> Terminale, avec versionnement des programmes pour les réformes.

INSERT INTO academic_programs(name, country, education_level, school_year, source_name, source_url) VALUES
('Programme secondaire général et technique — socle LEVEL UP', 'Côte d''Ivoire', 'Secondaire', '2025-2026', 'Direction de la Pédagogie et de la Formation Continue (DPFC)', 'https://dpfc-ci.net/?page_id=283');

INSERT INTO classes(program_id, code, name, description, order_index)
SELECT id, x.code, x.name, x.description, x.ord
FROM academic_programs p
CROSS JOIN (VALUES
 ('6E','6e','Premier niveau du secondaire.',1),
 ('5E','5e','Deuxième niveau du secondaire.',2),
 ('4E','4e','Troisième niveau du secondaire.',3),
 ('3E','3e','Quatrième niveau du secondaire.',4),
 ('2NDE','2nde','Seconde générale et parcours techniques selon l’offre.',5),
 ('1ERE','1ère','Première, avec séries/parcours selon le programme.',6),
 ('TLE','Terminale','Terminale, avec séries/parcours selon le programme.',7)
) AS x(code,name,description,ord)
WHERE p.name='Programme secondaire général et technique — socle LEVEL UP';

INSERT INTO academic_programs(name, country, education_level, school_year, source_name, source_url) VALUES
('Nouveaux programmes expérimentaux — collège', 'Côte d''Ivoire', 'Secondaire premier cycle', '2025-2026', 'DPFC — expérimentation', 'https://dpfc-ci.net/dpfc/2026/textes_officiels/mena/1/Circulaire%20N%C2%B0%200305_%20Exp%C3%A9rimentation%20des%20nouveaux%20programmes%20éducatifs.pdf');

-- 15. FILIÈRES DE DÉPART
-- =========================

INSERT INTO tracks(name, code, category) VALUES
('Générale', 'GENERAL', 'general'),
('Électronique', 'ELEC', 'technical'),
('Électricité d’équipement', 'ELEC_EQ', 'technical'),
('Bâtiment et Travaux Publics', 'BTP', 'technical'),
('Mécanique automobile', 'MEC_AUTO', 'technical'),
('Maintenance véhicules et engins', 'MVE', 'technical'),
('Agriculture', 'AGRI', 'vocational'),
('Élevage', 'ELEVAGE', 'vocational'),
('Agroalimentaire', 'AGRO', 'vocational'),
('Réfrigération et climatisation', 'FRIGO', 'technical'),
('Chaudronnerie et soudure', 'SOUDURE', 'technical'),
('Pêche et aquaculture', 'PECHE', 'vocational');

-- =========================
-- 16. MATIÈRES DE DÉPART
-- =========================

INSERT INTO subjects(name, code, description) VALUES
('Mathématiques', 'MATH', 'Mathématiques'),
('Physique-Chimie', 'PC', 'Physique et chimie'),
('Sciences de la Vie et de la Terre', 'SVT', 'Sciences de la vie et de la Terre'),
('Français', 'FR', 'Français'),
('Anglais', 'ANG', 'Anglais'),
('Histoire-Géographie', 'HG', 'Histoire et géographie'),
('Informatique / TICE', 'TICE', 'Technologies de l’information et de la communication'),
('Électronique', 'ELECTRONIQUE', 'Électronique'),
('Électricité', 'ELECTRICITE', 'Électricité'),
('Technologie du bâtiment', 'BATIMENT', 'Technologie du bâtiment'),
('Mécanique', 'MECANIQUE', 'Mécanique'),
('Agriculture', 'AGRICULTURE', 'Sciences et techniques agricoles'),
('Élevage', 'ELEVAGE_MATIERE', 'Sciences et techniques de l’élevage'),
('Agroalimentaire', 'AGROALIMENTAIRE', 'Transformation agroalimentaire'),
('Réfrigération-Climatisation', 'CLIM', 'Réfrigération et climatisation'),
('Chaudronnerie-Soudure', 'CHAUD_SOUD', 'Chaudronnerie et soudure'),
('Pêche-Aquaculture', 'PECHE_AQUA', 'Pêche et aquaculture');


-- =========================
-- 17. MODE MULTI + CHAT EN DIRECT
-- =========================

CREATE TABLE multi_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    room_code VARCHAR(12) UNIQUE NOT NULL,
    title VARCHAR(200),
    status VARCHAR(20) NOT NULL DEFAULT 'waiting'
        CHECK (status IN ('waiting','active','finished','cancelled')),
    max_participants INTEGER NOT NULL DEFAULT 45
        CHECK (max_participants BETWEEN 2 AND 45),
    current_lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
    current_exercise_id UUID REFERENCES exercises(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ
);

CREATE TABLE multi_session_members (
    session_id UUID NOT NULL REFERENCES multi_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'member'
        CHECK (role IN ('host','member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    left_at TIMESTAMPTZ,
    is_online BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY(session_id, user_id)
);

CREATE TABLE multi_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES multi_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    message TEXT NOT NULL CHECK (length(message) BETWEEN 1 AND 3000),
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE multi_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES multi_sessions(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    answer TEXT,
    is_correct BOOLEAN NOT NULL,
    xp_earned INTEGER NOT NULL DEFAULT 0,
    answered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_multi_sessions_code ON multi_sessions(room_code);
CREATE INDEX idx_multi_members_session ON multi_session_members(session_id);
CREATE INDEX idx_multi_chat_session_time ON multi_chat_messages(session_id, sent_at);
CREATE INDEX idx_multi_answers_session ON multi_answers(session_id, answered_at);


-- =========================
-- 18. PROGRESSION ADAPTATIVE
-- =========================
CREATE TABLE user_adaptive_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    adaptive_level INTEGER NOT NULL DEFAULT 1 CHECK (adaptive_level BETWEEN 1 AND 5),
    correct_count INTEGER NOT NULL DEFAULT 0,
    incorrect_count INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- 19. EXAMENS / EXAMENS BLANCS
-- =========================
CREATE TABLE exams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    exam_type VARCHAR(30) NOT NULL CHECK (exam_type IN ('BEPC','BAC','TRAINING')),
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    track_id UUID REFERENCES tracks(id) ON DELETE SET NULL,
    subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 900,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE exam_questions (
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(exam_id, exercise_id)
);
CREATE TABLE exam_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score INTEGER NOT NULL DEFAULT 0,
    total_questions INTEGER NOT NULL DEFAULT 0,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ
);

-- =========================
-- 20. ESPACE ENSEIGNANT
-- =========================
CREATE TABLE teacher_classes (
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    academic_year VARCHAR(20),
    PRIMARY KEY(teacher_id, class_id, academic_year)
);
CREATE TABLE teacher_missions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    xp_reward INTEGER NOT NULL DEFAULT 0,
    due_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- 21. MODE FAIBLE CONNEXION
-- =========================
CREATE TABLE offline_content_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    track_id UUID REFERENCES tracks(id) ON DELETE SET NULL,
    size_bytes BIGINT,
    version VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE user_offline_packs (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pack_id UUID NOT NULL REFERENCES offline_content_packs(id) ON DELETE CASCADE,
    downloaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_synced_at TIMESTAMPTZ,
    PRIMARY KEY(user_id, pack_id)
);

-- =========================
-- 22. LIGUES / SAISONS
-- =========================
CREATE TABLE leagues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(80) NOT NULL,
    min_xp INTEGER NOT NULL,
    max_xp INTEGER,
    icon VARCHAR(20)
);
CREATE TABLE league_seasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL
);
CREATE TABLE user_league_memberships (
    season_id UUID NOT NULL REFERENCES league_seasons(id) ON DELETE CASCADE,
    league_id UUID NOT NULL REFERENCES leagues(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    xp_snapshot INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(season_id, league_id, user_id)
);

CREATE INDEX idx_multi_sessions_capacity ON multi_sessions(max_participants);

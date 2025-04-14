-- Create ENUM type for agent status
CREATE TYPE agent_status AS ENUM ('pending', 'active', 'broken', 'stopped');

-- Main agent card table
CREATE TABLE agent_cards (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    url VARCHAR(500) NOT NULL,
    version VARCHAR(100) NOT NULL,
    documentation_url VARCHAR(500),
    status agent_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Provider information
CREATE TABLE agent_providers (
    id SERIAL PRIMARY KEY,
    agent_card_id INTEGER REFERENCES agent_cards(id) ON DELETE CASCADE,
    organization VARCHAR(255) NOT NULL,
    url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agent capabilities
CREATE TABLE agent_capabilities (
    id SERIAL PRIMARY KEY,
    agent_card_id INTEGER REFERENCES agent_cards(id) ON DELETE CASCADE,
    streaming BOOLEAN DEFAULT FALSE,
    push_notifications BOOLEAN DEFAULT FALSE,
    state_transition_history BOOLEAN DEFAULT FALSE,
    human_intervention BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Authentication schemes
CREATE TABLE agent_authentication (
    id SERIAL PRIMARY KEY,
    agent_card_id INTEGER REFERENCES agent_cards(id) ON DELETE CASCADE,
    credentials TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Authentication schemes (many-to-many relationship)
CREATE TABLE agent_auth_schemes (
    id SERIAL PRIMARY KEY,
    agent_authentication_id INTEGER REFERENCES agent_authentication(id) ON DELETE CASCADE,
    scheme VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Input/output modes
CREATE TABLE agent_modes (
    id SERIAL PRIMARY KEY,
    agent_card_id INTEGER REFERENCES agent_cards(id) ON DELETE CASCADE,
    mode_type VARCHAR(50) NOT NULL, -- 'input' or 'output'
    mode_value VARCHAR(100) NOT NULL, -- e.g., 'text', 'file', 'json'
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agent skills
CREATE TABLE agent_skills (
    id SERIAL PRIMARY KEY,
    agent_card_id INTEGER REFERENCES agent_cards(id) ON DELETE CASCADE,
    skill_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Skill tags (many-to-many relationship)
CREATE TABLE agent_skill_tags (
    id SERIAL PRIMARY KEY,
    agent_skill_id INTEGER REFERENCES agent_skills(id) ON DELETE CASCADE,
    tag VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Skill examples
CREATE TABLE agent_skill_examples (
    id SERIAL PRIMARY KEY,
    agent_skill_id INTEGER REFERENCES agent_skills(id) ON DELETE CASCADE,
    example TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Skill input/output modes
CREATE TABLE agent_skill_modes (
    id SERIAL PRIMARY KEY,
    agent_skill_id INTEGER REFERENCES agent_skills(id) ON DELETE CASCADE,
    mode_type VARCHAR(50) NOT NULL, -- 'input' or 'output'
    mode_value VARCHAR(100) NOT NULL, -- e.g., 'text', 'file', 'json'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Human intervention requests
CREATE TABLE human_intervention_requests (
    id SERIAL PRIMARY KEY,
    agent_card_id INTEGER REFERENCES agent_cards(id) ON DELETE CASCADE,
    task_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, assigned, in_progress, resolved, rejected
    priority VARCHAR(20) NOT NULL DEFAULT 'normal', -- low, normal, high, critical
    reason TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_note TEXT,
    timeout_seconds INTEGER, -- Optional timeout after which to proceed without intervention
    callback_url VARCHAR(500) -- URL to notify when human intervention is complete
);

-- Human intervention context data
CREATE TABLE intervention_context (
    id SERIAL PRIMARY KEY,
    intervention_id INTEGER REFERENCES human_intervention_requests(id) ON DELETE CASCADE,
    context_type VARCHAR(50) NOT NULL, -- conversation, error, user_input, etc.
    context_data JSONB NOT NULL, -- Flexible JSON structure to store context
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Human operators who can respond to intervention requests
CREATE TABLE human_operators (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Assignments of human operators to intervention requests
CREATE TABLE intervention_assignments (
    id SERIAL PRIMARY KEY,
    intervention_id INTEGER REFERENCES human_intervention_requests(id) ON DELETE CASCADE,
    operator_id INTEGER REFERENCES human_operators(id) ON DELETE SET NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Human actions/decisions taken during intervention
CREATE TABLE intervention_actions (
    id SERIAL PRIMARY KEY,
    intervention_id INTEGER REFERENCES human_intervention_requests(id) ON DELETE CASCADE,
    operator_id INTEGER REFERENCES human_operators(id) ON DELETE SET NULL,
    action_type VARCHAR(100) NOT NULL,
    action_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

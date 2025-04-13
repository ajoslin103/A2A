# Agent Card Database Schema for A2A Protocol

This schema defines a PostgreSQL database structure for storing Agent2Agent (A2A) protocol agent cards.

## Database Tables

```sql
-- Main agent card table
CREATE TABLE agent_cards (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    url VARCHAR(500) NOT NULL,
    version VARCHAR(100) NOT NULL,
    documentation_url VARCHAR(500),
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
```

## Key Design Decisions

1. **Normalized Structure**: The database design is normalized to reduce redundancy and maintain data integrity.

2. **One-to-One and One-to-Many Relationships**: Each agent card has one provider and one set of capabilities, but can have multiple skills, authentication schemes, and input/output modes.

3. **Timestamps**: Timestamps track when records are created and updated, which is helpful for versioning and auditing.

4. **Flexible Mode Storage**: Input and output modes are stored in a way that supports both agent-level defaults and skill-specific modes.

5. **Cascading Deletes**: When an agent card is deleted, all related records are automatically deleted to maintain referential integrity.

6. **State Preservation for Human Intervention**: The system maintains the complete state of agent tasks when human intervention is requested, allowing seamless resumption of the workflow after human input.

## Entity Relationships

- **agent_cards**: The central entity representing an A2A agent
- **agent_providers**: One-to-one relationship with agent_cards
- **agent_capabilities**: One-to-one relationship with agent_cards
- **agent_authentication**: One-to-one relationship with agent_cards
- **agent_auth_schemes**: Many-to-one relationship with agent_authentication
- **agent_modes**: Many-to-one relationship with agent_cards
- **agent_skills**: Many-to-one relationship with agent_cards
- **agent_skill_tags**: Many-to-one relationship with agent_skills
- **agent_skill_examples**: Many-to-one relationship with agent_skills
- **agent_skill_modes**: Many-to-one relationship with agent_skills
- **human_intervention_requests**: Many-to-one relationship with agent_cards
- **intervention_context**: Many-to-one relationship with human_intervention_requests
- **human_operators**: Independent entity for human staff management
- **intervention_assignments**: Many-to-many relationship between human_operators and human_intervention_requests
- **intervention_actions**: Records of actions taken by human operators

## Human Intervention Workflow

The human intervention extension enables a "suspend and resume" pattern for agent workflows:

1. When an agent encounters a situation requiring human judgment, it initiates a human intervention request
2. The system preserves the complete state of the task in the intervention_context table
3. Human operators are assigned to review and address the request
4. Human decisions and actions are recorded in the intervention_actions table
5. Upon resolution, the agent can retrieve both the intervention outcome and its previous state
6. The agent workflow resumes from exactly where it left off

This design supports both synchronous interventions (where an agent waits for human input) and asynchronous interventions (where requests are queued for later review). The callback mechanism allows for automatic notification when human intervention is complete.

The human intervention tables create a comprehensive audit trail of when human judgment was required in agentic workflows, which is valuable for understanding, debugging, and improving agent performance over time.
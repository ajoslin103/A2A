import uuid
import json
from datetime import datetime
import math
import random
import sys
import os

def make_rectangle(x, y, width, height, label, color="#f8f9fa"):
    return {
        "id": str(uuid.uuid4()),
        "type": "rectangle",
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        "angle": 0,
        "strokeColor": "#1e1e1e",
        "backgroundColor": color,
        "fillStyle": "solid",
        "strokeWidth": 1,
        "strokeStyle": "solid",
        "roughness": 1,
        "opacity": 100,
        "groupIds": [],
        "seed": int(uuid.uuid4().int & 0xffffff),
        "version": 1,
        "versionNonce": int(uuid.uuid4().int & 0xffffff),
        "isDeleted": False,
        "boundElements": [
            {
                "type": "text",
                "id": f"{uuid.uuid4()}"
            }
        ],
        "updated": int(datetime.now().timestamp() * 1000),
        "link": None,
        "locked": False
    }

def make_text(x, y, width, height, text):
    return {
        "id": str(uuid.uuid4()),
        "type": "text",
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        "angle": 0,
        "strokeColor": "#1e1e1e",
        "backgroundColor": "transparent",
        "fillStyle": "hachure",
        "strokeWidth": 1,
        "strokeStyle": "solid",
        "roughness": 1,
        "opacity": 100,
        "groupIds": [],
        "seed": int(uuid.uuid4().int & 0xffffff),
        "version": 1,
        "versionNonce": int(uuid.uuid4().int & 0xffffff),
        "isDeleted": False,
        "boundElements": None,
        "updated": int(datetime.now().timestamp() * 1000),
        "link": None,
        "locked": False,
        "text": text,
        "fontSize": 16,
        "fontFamily": 1,
        "textAlign": "center",
        "verticalAlign": "middle",
        "baseline": 18,
        "containerId": None,
        "originalText": text
    }

def make_arrow(from_x, from_y, to_x, to_y):
    return {
        "id": str(uuid.uuid4()),
        "type": "arrow",
        "x": from_x,
        "y": from_y,
        "width": to_x - from_x,
        "height": to_y - from_y,
        "angle": 0,
        "strokeColor": "#000000",
        "backgroundColor": "transparent",
        "fillStyle": "hachure",
        "strokeWidth": 2,
        "strokeStyle": "solid",
        "roughness": 0,
        "opacity": 100,
        "groupIds": [],
        "seed": int(uuid.uuid4().int & 0xfffffff),
        "version": 1,
        "versionNonce": int(uuid.uuid4().int & 0xfffffff),
        "isDeleted": False,
        "boundElements": [],
        "updated": int(datetime.now().timestamp() * 1000),
        "points": [[0, 0], [to_x - from_x, to_y - from_y]],
        "startBinding": None,
        "endBinding": None,
        "startArrowhead": None,
        "endArrowhead": "arrow",
        "locked": False
    }

# Table groups with color coding
table_groups = {
    "core": ["agent_cards", "agent_providers", "agent_capabilities"],
    "auth": ["agent_authentication", "agent_auth_schemes"],
    "skills": ["agent_skills", "agent_skill_tags", "agent_skill_examples", "agent_skill_modes"],
    "intervention": ["human_intervention_requests", "intervention_context", "human_operators", 
                    "intervention_assignments", "intervention_actions"]
}

# Colors for each group
group_colors = {
    "core": "#d1e7dd",  # Light green
    "auth": "#cfe2ff",  # Light blue
    "skills": "#fff3cd", # Light yellow
    "intervention": "#f8d7da"  # Light red
}

# Get color for a table based on its group
def get_table_color(table_name):
    for group, tables in table_groups.items():
        if table_name in tables:
            return group_colors[group]
    return "#f8f9fa"  # Default light gray

# Table positions on the diagram
positions = {
    "agent_cards": (100, 100),
    "agent_providers": (350, 50),
    "agent_capabilities": (350, 150),
    "agent_authentication": (350, 250),
    "agent_auth_schemes": (600, 250),
    "agent_modes": (350, 350),
    "agent_skills": (100, 250),
    "agent_skill_tags": (-150, 250),
    "agent_skill_examples": (-150, 350),
    "agent_skill_modes": (100, 350),
    "human_intervention_requests": (100, 500),
    "intervention_context": (350, 500),
    "human_operators": (-150, 500),
    "intervention_assignments": (-150, 600),
    "intervention_actions": (100, 600),
}

# Table relationships for drawing arrows
relationships = [
    ("agent_cards", "agent_providers"),
    ("agent_cards", "agent_capabilities"),
    ("agent_cards", "agent_authentication"),
    ("agent_authentication", "agent_auth_schemes"),
    ("agent_cards", "agent_modes"),
    ("agent_cards", "agent_skills"),
    ("agent_skills", "agent_skill_tags"),
    ("agent_skills", "agent_skill_examples"),
    ("agent_skills", "agent_skill_modes"),
    ("agent_cards", "human_intervention_requests"),
    ("human_intervention_requests", "intervention_context"),
    ("human_intervention_requests", "intervention_assignments"),
    ("human_intervention_requests", "intervention_actions"),
    ("intervention_assignments", "human_operators"),
    ("intervention_actions", "human_operators"),
]

# Initialize Excalidraw data structure
excalidraw_data = {
    "type": "excalidraw",
    "version": 2,
    "source": "A2A Agent Card Schema Generator",
    "elements": [],
    "appState": {
        "viewBackgroundColor": "#ffffff",
        "gridSize": 20
    }
}

# Generate rectangles for tables
for table_name, (x, y) in positions.items():
    width = 200
    height = 100
    color = get_table_color(table_name)
    
    # Create rectangle
    rectangle = make_rectangle(x, y, width, height, table_name, color)
    excalidraw_data["elements"].append(rectangle)
    
    # Create text label
    text = make_text(x, y, width, height, table_name)
    excalidraw_data["elements"].append(text)

# Generate arrows for relationships
arrows = []
for from_tbl, to_tbl in relationships:
    from_x, from_y = positions[from_tbl]
    to_x, to_y = positions[to_tbl]
    # Adjust arrow positions to connect to the edges of rectangles
    arrows.append(make_arrow(from_x + 100, from_y + 50, to_x + 100, to_y + 50))

# Add arrows to document
excalidraw_data["elements"].extend(arrows)

# Save the Excalidraw file
output_file = "a2a_agent_card_schema.excalidraw"
with open(output_file, "w") as f:
    json.dump(excalidraw_data, f, indent=2)

print(f"Excalidraw diagram saved to: {output_file}")
print("You can import this file into Excalidraw (https://excalidraw.com) by using the 'Open' button.")

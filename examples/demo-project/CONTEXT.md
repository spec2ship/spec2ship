# TaskTracker - Project Context

## Project Overview

TaskTracker is a CLI-based task management application for developers who work primarily in the terminal. It provides simple, fast task tracking without leaving the command line.

## Target Users

### Primary: Solo Developer (Alex)
- Works primarily in terminal
- Manages personal projects and todos
- Values speed over features
- Uses Git for version control

### Secondary: Team Lead (Sam)
- Coordinates small team (2-5 people)
- Needs visibility into task progress
- Prefers text-based workflows
- Integrates with existing tools

## Core Features

1. **Task CRUD**: Create, read, update, delete tasks from CLI
2. **Status Workflow**: todo → in-progress → done
3. **Priority Levels**: high, medium, low
4. **Git Integration**: Link tasks to commits/branches
5. **Local Storage**: File-based, no server required

## Technical Constraints

- Must work offline
- Single binary distribution
- No external dependencies
- Cross-platform (macOS, Linux, Windows)

## Business Rules

- BR-001: Tasks must have a unique ID
- BR-002: Status transitions are validated (can't go from done to todo)
- BR-003: High priority tasks appear first in listings
- BR-004: Completed tasks are archived after 30 days
- BR-005: Task IDs are never reused

## Non-Functional Requirements

- Startup time < 100ms
- Handle 10,000+ tasks without performance degradation
- Data file size < 10MB for typical usage

---

*This is an example CONTEXT.md for demonstration purposes.*

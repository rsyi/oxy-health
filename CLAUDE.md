# Oxy Project - Testing & Execution Guide

This document provides instructions for Claude Code (and other AI assistants) to test and execute Oxy agents, workflows, and SQL files in any repository.

## Quick Command Reference (Copy-Paste Ready)

### Direct Oxy Commands

**Run Agent Files** (require a question/prompt):
```bash
oxy run <agent-file>.agent.yml "Your question here"
```

**Run Workflow Files**:
```bash
oxy run <workflow-file>.workflow.yml
```

**Run SQL Files**:
```bash
oxy run <query-file>.sql
```

**Run SQL with Variables**:
```bash
oxy run <query-file>.sql -v variable_name=value -v another_var=value
```

**Dry Run SQL** (validate without executing):
```bash
oxy run <query-file>.sql --dry-run
```

### Make Commands

**Discovery & Validation**:
```bash
make discover            # List all Oxy files in project
make validate            # Validate Oxy configuration
make help                # Show all available commands
```

**Parameterized Execution**:
```bash
# Run an agent
make run-agent FILE=path/to/agent.agent.yml PROMPT="Your question"

# Run a workflow
make run-workflow FILE=path/to/workflow.workflow.yml

# Run SQL query
make run-sql FILE=path/to/query.sql

# Run SQL with variables
make run-sql FILE=path/to/query.sql VARS="year=2024 status=active"
```

**Testing**:
```bash
make test-sql            # Test all SQL files
make test-workflows      # Test all workflow files
make test-all            # Run all tests
```

## Overview

This repository uses Oxy, a data analysis and workflow framework. Oxy supports three main file types:

- **`.agent.yml`** - AI agents for data analysis and insights
- **`.workflow.yml`** - Data processing workflows
- **`.sql`** - SQL queries (with optional Jinja2 templating)

## File Discovery

To see what Oxy assets are available:
```bash
make discover
```

This will list all agents, workflows, and SQL files in the project.

## Common Usage Patterns

### 1. Testing Agent Files

Agents require a prompt to execute. Test an agent with:
```bash
oxy run path/to/agent.agent.yml "Analyze the data and provide insights"
```

Or using make:
```bash
make run-agent FILE=path/to/agent.agent.yml PROMPT="What are the key trends?"
```

### 2. Testing SQL Files

Run SQL directly:
```bash
oxy run path/to/query.sql
```

Or validate without executing:
```bash
oxy run path/to/query.sql --dry-run
```

Or using make:
```bash
make run-sql FILE=path/to/query.sql
```

### 3. Testing SQL with Variables

If SQL files use Jinja2 templates (e.g., `{{ variable_name }}`):
```bash
oxy run path/to/query.sql -v variable_name=value -v year=2024
```

Or using make:
```bash
make run-sql FILE=path/to/query.sql VARS="variable_name=value year=2024"
```

### 4. Testing Workflow Files

Run a workflow:
```bash
oxy run path/to/workflow.workflow.yml
```

Or using make:
```bash
make run-workflow FILE=path/to/workflow.workflow.yml
```

### 5. Bulk Testing

Test all SQL files and workflows in the project:
```bash
make test-all
```

## Validation

Before testing, validate the Oxy configuration:
```bash
make validate
```

This checks:
- Oxy CLI is installed
- Configuration files are valid
- Project structure is correct

## Troubleshooting

### Common Issues

1. **"oxy command not found"**
   - Install Oxy CLI from: https://github.com/oxy-hq/oxy
   - Check with: `which oxy`

2. **"No such file or directory"**
   - Use `make discover` to see available files
   - Check file paths are correct (use tab completion)

3. **Agent fails to execute**
   - Ensure you're providing a PROMPT parameter
   - Example: `make run-agent FILE=agent.agent.yml PROMPT="question"`

4. **SQL query fails**
   - Try dry-run first: `oxy run query.sql --dry-run`
   - Check if query requires variables: look for `{{ }}` in SQL
   - Verify database connection in configuration

5. **Variables not working**
   - Ensure SQL uses Jinja2 syntax: `{{ variable_name }}`
   - Pass variables with `-v`: `oxy run query.sql -v variable_name=value`
   - In make: `VARS="var1=value1 var2=value2"` (space-separated)

### Getting Help

```bash
oxy --help              # General Oxy help
oxy run --help          # Help for run command
make help               # See all make targets
```

## Oxy Command Syntax Reference

### Agent Execution
```bash
oxy run <file>.agent.yml "question or prompt"
```
- **Required**: Agent file path and question/prompt
- **Optional**: `--retry` for automatic retry on failure

### Workflow Execution
```bash
oxy run <file>.workflow.yml
```
- **Required**: Workflow file path
- **Optional**: `--retry` for automatic retry

### SQL Execution
```bash
oxy run <file>.sql [OPTIONS]
```
- **Required**: SQL file path
- **Optional**:
  - `-v, --variables VAR=VALUE` - Pass template variables
  - `--database NAME` - Override database connection
  - `--dry-run` - Preview SQL without executing

## Agent Configuration and Jinja Templating

### Built-in Jinja Variables for Databases

Oxy provides built-in Jinja template variables for referencing database information in agent `system_instructions`. **Do not use file-type context for schema information** - use these built-in variables instead.

#### Available Database Properties

Access database properties using `{{ databases.DATABASE_NAME.property }}`:

- **`{{ databases.DATABASE_NAME.name }}`** - The database name as configured in `config.yml`
- **`{{ databases.DATABASE_NAME.dialect }}`** - The SQL dialect (e.g., "duckdb", "postgres", "snowflake", "bigquery")
- **`{{ databases.DATABASE_NAME.datasets }}`** - A dictionary of schemas/datasets and their table patterns

#### Example Usage in Agent System Instructions

```yaml
model: "openai"

system_instructions: |
  You are a data analyst. Write and execute SQL to answer questions.

  Database: {{ databases.motherduck.name }}
  Dialect: {{ databases.motherduck.dialect }}

  # Available Tables and Schemas
  {{ databases.motherduck.datasets }}

  # Additional context...

tools:
  - name: execute_sql
    type: execute_sql
    database: motherduck
```

#### Iterating Over Datasets

You can also iterate over datasets in Jinja:

```jinja
Available datasets:
{% for dataset, tables in databases.my_database.datasets.items() %}
- Schema: {{ dataset }}
  Tables: {{ tables | join(", ") }}
{% endfor %}
```

#### Important Notes

1. **Schema files must be synced**: Run `oxy sync` to generate `.databases/**/*.sem.yml` files from your database metadata
2. **Use built-in variables, not file context**: Don't add `.databases/**/*.sem.yml` files as file-type context - the `databases` object already includes this information
3. **Database must be configured**: The database must be defined in `config.yml` with proper credentials
4. **Schema location**: Semantic models are stored in `.databases/{database_name}/{schema}/{table}.sem.yml`

### Generating Database Schema Files

To populate the `.databases/` directory with schema information:

```bash
oxy sync
```

This command:
- Connects to all configured databases
- Queries `INFORMATION_SCHEMA` for table and column metadata
- Generates `.sem.yml` files for each table
- Makes schema information available via `{{ databases.*.datasets }}`

## Example Workflows

### Example 1: Test a New Agent
```bash
# Discover agents
make discover

# Test specific agent
make run-agent FILE=analysis-agent.agent.yml PROMPT="Summarize last quarter"
```

### Example 2: Run Parameterized SQL Query
```bash
# Discover SQL files
make discover

# Run with parameters
make run-sql FILE=reports/monthly.sql VARS="year=2024 month=12"
```

### Example 3: Validate Before Running
```bash
# Validate configuration
make validate

# Test all SQL (dry-run where possible)
make test-sql

# Run workflow
make run-workflow FILE=data-pipeline.workflow.yml
```

## Integration with Claude Code

When Claude Code is testing Oxy assets:

1. **Always validate first**: `make validate`
2. **Discover files**: `make discover` to see what's available
3. **Use make commands** for consistency and error handling
4. **Test incrementally**: Test individual files before bulk testing
5. **Check for variables**: Look for `{{ }}` in SQL files before running

## Continuous Improvement: Update This Documentation

**IMPORTANT**: This section contains critical instructions for Claude Code and AI assistants.

### The Documentation Feedback Loop

This CLAUDE.md file and associated Makefile serve as **templates** that may be copied to new project directories. When you learn something new while working with Oxy, you MUST update the base template files in **this directory** (`/Users/robertyi/repos/oxy-claude/`), not in any derived project directories.

### When to Update Documentation

Update the base template files whenever you:

1. **Discover new Oxy commands or options** not documented here
2. **Encounter and solve new errors** not listed in Troubleshooting
3. **Learn new patterns** for working with agents, workflows, or SQL
4. **Find better ways** to structure commands or Makefile targets
5. **Identify missing validation checks** that should be added to the Makefile
6. **Discover new edge cases** in file execution or variable passing
7. **Learn about Oxy configuration options** not mentioned in this guide
8. **Find useful debugging techniques** that would help future users

### What to Update

Based on the type of learning:

- **CLAUDE.md** - Add to Troubleshooting, Best Practices, or create new sections
- **Makefile** - Add new targets, improve error handling, add validation checks
- **README.md** - Update overview information or quick start guides

### How to Identify Context

Before updating, determine your context:

1. **Check for .oxy-base file**:
   ```bash
   cat .oxy-base
   ```
   - If present: You're in a **derived project directory**
   - If absent: You're likely in the **base template directory**

2. **Working in the base template directory?**
   - No `.oxy-base` file exists
   - Update files directly (CLAUDE.md, Makefile, etc.)

3. **Working in a derived project directory?**
   - `.oxy-base` file exists and contains `TEMPLATE_BASE=/path/to/template`
   - Note your learnings during the session
   - **Read the base location**: `TEMPLATE_BASE=$(grep TEMPLATE_BASE .oxy-base | cut -d= -f2)`
   - **Switch to base directory**: `cd $TEMPLATE_BASE` or use the path from `.oxy-base`
   - Update files there
   - Inform the user that you've updated the base templates

4. **If .oxy-base is missing but you're in a project**:
   - Ask the user: "Where is your oxy-claude template base directory?"
   - Note the location for updates

### Update Guidelines

When updating documentation:

1. **Be specific**: Include exact commands, error messages, and solutions
2. **Maintain structure**: Follow existing formatting and organization
3. **Test your additions**: Ensure commands work before documenting them
4. **Update the date**: Change "Last Updated" date at the bottom
5. **Explain context**: Add brief notes about when/why to use new information
6. **Keep it actionable**: Focus on what to do, not just what went wrong

### Example Update Scenarios

**Scenario 1**: You discover that `oxy run` has a `--format json` option for machine-readable output.
- **Action**: Add to "Oxy Command Syntax Reference" section in CLAUDE.md
- **Location**: Base template CLAUDE.md (find via `.oxy-base` file)

**Scenario 2**: You encounter an error about missing database credentials not covered in Troubleshooting.
- **Action**: Add new numbered item to "Common Issues" in Troubleshooting section
- **Location**: Base template CLAUDE.md (find via `.oxy-base` file)

**Scenario 3**: You find that the Makefile should validate file existence before running.
- **Action**: Add validation check to relevant Makefile targets
- **Location**: Base template Makefile (find via `.oxy-base` file)

**Scenario 4**: You learn a new pattern for testing agents with multiple prompts.
- **Action**: Add new example to "Example Workflows" section
- **Location**: Base template CLAUDE.md (find via `.oxy-base` file)

### Communicating Updates to Users

When you update base template files:

1. **Inform the user**: Briefly explain what you learned and what you updated
2. **Show the change**: Reference the file and section you modified
3. **Explain the benefit**: Describe how this improves future Oxy work
4. **Suggest review**: Ask if the update aligns with their understanding

Example notification:
```
I've updated the base template documentation:
- File: CLAUDE.md in the template base directory
- Change: Added troubleshooting step for [specific error]
- Solution: [specific command or fix]
This will help when working with similar projects in the future.
```

### Base Directory Reference

**How derived projects find the base template**:

Derived projects have a `.oxy-base` file that tracks the template location:
```bash
cat .oxy-base
# Output: TEMPLATE_BASE=/path/to/oxy-claude
```

To programmatically find the base directory:
```bash
# From a derived project
TEMPLATE_BASE=$(grep TEMPLATE_BASE .oxy-base | cut -d= -f2)
cd "$TEMPLATE_BASE"
```

**Files to potentially update in base template**:
- `CLAUDE.md` - Main instructions (this file)
- `Makefile` - Build and test automation
- `README.md` - Project overview
- `setup-oxy-project.sh` - Bootstrap script

## Project Structure

Typical Oxy project structure:
```
project/
├── config.yml                  # Oxy configuration
├── *.agent.yml                 # Agent definitions
├── *.workflow.yml              # Workflow definitions
├── queries/                    # SQL queries
│   └── *.sql
├── semantic_models/            # Semantic layer definitions
│   └── *.sem.yml
├── Makefile                    # This testing framework
└── CLAUDE.md                   # This file
```

## Best Practices

1. **Use descriptive file names**: `sales-analysis.agent.yml` > `agent1.agent.yml`
2. **Document SQL variables**: Add comments explaining required variables
3. **Test incrementally**: Validate → Test SQL → Test workflows → Test agents
4. **Use dry-run**: Always dry-run SQL before executing against production
5. **Version control**: Commit working queries to verified folders

## Additional Resources

- Oxy Documentation: https://github.com/oxy-hq/oxy
- Oxy CLI Help: `oxy --help`
- Make Help: `make help`

### DeepWiki Documentation (Fallback)

If you encounter Oxy features or behaviors not documented in this guide, use DeepWiki as a fallback resource:

**URL**: https://deepwiki.com/oxy-hq/oxy

**When to use DeepWiki**:
1. You encounter an Oxy error message not covered in Troubleshooting
2. You need to understand advanced Oxy features or configuration options
3. You're unsure about Oxy command syntax or parameters
4. You need examples of specific Oxy patterns not documented here

**How to use DeepWiki**:
- Ask specific questions about Oxy functionality
- Search for error messages or feature names
- Look up configuration options and their meanings
- Find examples of agent/workflow/SQL patterns

After learning from DeepWiki, **update this CLAUDE.md** with what you learned so future sessions don't need to look it up again.

---

**Last Updated**: October 2025
**Framework Version**: Generic v1.0
**Compatible with**: Any Oxy project

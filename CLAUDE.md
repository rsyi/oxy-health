# Oxy Project - Testing & Execution Guide

If you encounter Oxy features or behaviors not documented in this guide, use DeepWiki as a fallback resource:
<https://deepwiki.com/oxy-hq/oxy>

CRITICAL: When using deepwiki, you MUST:

Only search the oxy-hq/oxy repository - Do not search other repositories or
general documentation Frame requests from a user's perspective, not a
maintainer's perspective Search only oxy-hq/oxy Always use this exact prefix
for deepwiki queries:

"I am a user of this project, not its maintainer. Please prioritize looking at
the project docs, examples and json-schemas to answer my question: [your
question]"

For example:

✅ "As a user of this project, explain how to configure Toast API credentials"
✅ "I am a user of this project, not its maintainer. How do I set up the database?"
❌ Don't ask as if you're modifying or maintaining the underlying codebase

**When to use DeepWiki**:

1. You encounter an Oxy error message not covered in Troubleshooting
2. You need to understand advanced Oxy features or configuration options
3. You're unsure about Oxy command syntax or parameters
4. You need examples of specific Oxy patterns not documented here

## Quick Command Reference

### Core Oxy Commands

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

**Validate Configuration**:

```bash
oxy validate
```

**Sync Database Schemas**:

```bash
oxy sync
```


### File Discovery

**Find Oxy files using shell tools**:

```bash
# List all agents
find . -name "*.agent.yml"

# List all workflows
find . -name "*.workflow.yml"

# List all SQL files
find . -name "*.sql" -not -path "*/.*"

# List semantic layer files
find semantics/views -name "*.view.yml"
find semantics/topics -name "*.topic.yml"
```


## Validation

Before testing, validate the Oxy configuration with:

```bash
oxy validate
```

Note: this only validates agents and automations. To validate semantic files, you'll need to run `oxy build`.

### Getting Help

```bash
oxy --help              # General Oxy help
oxy run --help          # Help for run command
oxy validate --help     # Help for validate command
oxy sync --help         # Help for sync command
```


## Overview

This repository uses Oxy, a data analysis and workflow framework. Oxy supports multiple file types:

- **`.agent.yml`** - AI agents for data analysis and insights
- **`.workflow.yml`** - Data processing workflows
- **`.sql`** - SQL queries (with optional Jinja2 templating)
- **`.view.yml`** - Semantic layer view definitions (in `semantics/views/`)
- **`.topic.yml`** - Semantic layer topic definitions (in `semantics/topics/`)


# Generating Database Schema Files

The first step in any bootstrapping process is to determine the schema information. To populate the `.databases/` directory with schema information:

```bash
oxy sync
```

This command:

- Connects to all configured databases
- Queries `INFORMATION_SCHEMA` for table and column metadata
- Generates `.schema.yml` files for each table
- Makes schema information available via `{{ databases.*.datasets }}`

These files can be used as a base to generate the information for the semantic layer.

# Semantic Layer: Views and Topics

One of the main things that you will be asked to do is bootstrap a semantic layer for Oxy. Oxy provides a powerful semantic layer that transforms raw database schemas into business-friendly concepts for deterministic query generation. The semantic layer consists of **views** (`.view.yml`) and **topics** (`.topic.yml`) files.

Documentation about the semantic layer can be found at:
- Overview: https://docs.oxy.tech/learn-about-oxy/semantic-layer
- Views: https://docs.oxy.tech/learn-about-oxy/semantic-layer/views
- Entities: https://docs.oxy.tech/learn-about-oxy/semantic-layer/entities
- Dimensions: https://docs.oxy.tech/learn-about-oxy/semantic-layer/dimensions
- Measures: https://docs.oxy.tech/learn-about-oxy/semantic-layer/measures
- Topics: https://docs.oxy.tech/learn-about-oxy/semantic-layer/topics
- Global semantics: https://docs.oxy.tech/learn-about-oxy/semantic-layer/global-inheritance (to define global entities, dimensions, measures that can be inherited from in semantic layer files)

### Directory Structure

```
project/
├── semantics/
│   ├── views/           # Data model definitions
│   │   └── *.view.yml
│   └── topics/          # Business domain organization
│       └── *.topic.yml
```

## View Files (`.view.yml`)

Views define logical data models with dimensions, measures, and metrics. They provide rich business context for AI agents to generate accurate queries.

**Location**: `semantics/views/`

**Key Components**:

- **name**: Unique identifier for the view
- **description**: Business explanation of what the view represents
- **datasource**: Database name from `config.yml`
- **table**: Table name
- **entities**: Core objects in the data model used to infer joins
- **dimensions**: Attributes for grouping and filtering
- **measures**: Quantitative metrics and aggregations

**Example View File** (`semantics/views/orders.view.yml`):

```yaml
name: orders
description: "Order transactions and related data"
datasource: "local"
table: "orders.csv"

entities:
  - name: order
    type: primary
    description: "Individual order transaction"
    key: order_id

dimensions:
  - name: order_status
    type: string
    description: "Current status of the order"
    expr: status
    samples: ["pending", "shipped", "delivered", "cancelled"]
    synonyms: ["status", "order_state", "fulfillment_status"]

  - name: order_year
    type: number
    description: "Year when order was placed"
    expr: "EXTRACT(YEAR FROM order_date)"
    synonyms: ["year"]

measures:
  - name: total_revenue
    type: sum
    description: "Total revenue from all orders"
    expr: total_amount
    synonyms: ["total sales", "gross revenue"]

  - name: avg_order_value
    type: average
    description: "Average order value"
    expr: total_amount
```

### Entity Types

Entities represent distinct objects or concepts in your data model (customers, orders, products, etc.). They enable automatic relationship discovery and intelligent joins between views.

**Primary Entity**: Each view should have exactly one primary entity representing the main subject of that view.

**Foreign Entity**: These reference objects primarily defined in other views, establishing relationships between different data sources.

### Entity Properties

- **name**: Unique identifier for the entity (required)
- **type**: Either "primary" or "foreign" (required)
- **description**: Human-readable explanation (required)
- **key**: Dimension name that serves as the identifier (required, or use `keys` for composite keys)

**CRITICAL**: Entity keys must reference **dimension names**, not database column names. The dimension itself has an `expr` property that maps to the actual database column. Oxy uses entity keys to mark dimensions as primary keys in generated schemas and automatically generate join relationships between views.

**Example with Primary and Foreign Entities**:

```yaml
entities:
  - name: order
    type: primary
    description: "Individual customer order"
    key: order_id

  - name: customer
    type: foreign
    description: "Customer who placed the order"
    key: customer_id

  - name: restaurant
    type: foreign
    description: "Restaurant where order was placed"
    key: restaurant_id

dimensions:
  - name: order_id
    type: string
    description: "Unique order identifier"
    expr: order_id  # This is the actual column name

  - name: customer_id
    type: string
    description: "Customer identifier"
    expr: customer_id
```

### How Entities Enable Joins

When entities are consistently defined across views with the same name, Oxy automatically:
1. Identifies relationships based on matching entity names
2. Generates JOIN clauses using entity keys
3. Enables cross-view queries without manual join logic

For example, if both `orders.view.yml` and `customers.view.yml` define a `customer` entity, Oxy will automatically know how to join these views when needed.

### Dimension Types

Supported dimension types:

- `string` - Text values
- `number` - Numeric values (integers, decimals)
- `date` - Date values
- `datetime` - Timestamp values
- `boolean` - True/false values

### Dimension Properties

- **name**: Unique identifier within the view (required)
- **type**: Data type (required)
- **description**: Business-friendly explanation (recommended)
- **expr**: SQL expression to calculate the dimension (required) - usually this is the column name
- **samples**: Example values for documentation (optional)
- **synonyms**: Alternative names for natural language queries (optional)

### Measure Types

Supported measure types:

- `count` - Count of records
- `count_distinct` - Count of unique values
- `sum` - Sum of values
- `average` - Average/mean of values
- `median` - Median value
- `min` - Minimum value
- `max` - Maximum value
- `stddev` - Standard deviation
- `custom` - Custom SQL expression

### Measure Properties

- **name**: Unique identifier within the view (required)
- **type**: Aggregation type (required)
- **description**: Business-friendly explanation (recommended)
- **expr**: SQL expression (required for most types, not for `count`)
- **filters**: Conditions to apply to the measure (optional)
- **synonyms**: Alternative names for natural language queries (optional)

### Filtered Measures

Apply conditions to measures for specific calculations:

```yaml
measures:
  - name: holiday_average_sales
    type: average
    description: "Average sales during holiday weeks only"
    expr: weekly_sales
    filters:
      - field: "is_holiday"
        op: "eq"
        value: true
```

## Topic Files (`.topic.yml`)

Topics organize related views by business domain, helping users discover and explore data concepts. **Best practice: Create one topic per view** to avoid duplication.

**Location**: `semantics/topics/`

**Key Components**:

- **name**: Unique identifier for the topic
- **description**: Business domain explanation
- **views**: Array of view names included in this topic
- **base_view**: Primary view for queries (optional)
- **default_filters**: Filters applied to all queries (optional)

**Example Topic File** (`semantics/topics/sales.topic.yml`):

```yaml
name: sales
description: "Sales performance and order management data"
base_view: orders
views:
  - orders
```

**Example with Default Filters**:

```yaml
name: active_sales
description: "Active sales data excluding cancelled orders"
base_view: orders
views:
  - orders
default_filters:
  - field: "status"
    op: "not_in"
    value: ["cancelled", "refunded"]
  - field: "is_test"
    op: "eq"
    value: false
```

## Creating Semantic Layer Files

### Step 1: Create Directory Structure

```bash
mkdir -p semantics/views semantics/topics
```

### Step 2: Create View Files

Create `.view.yml` files in `semantics/views/` for each logical data model. Include:

1. **Core dimensions**: Key attributes users will filter and group by
2. **Calculated dimensions**: Derived fields (e.g., year from date, price ranges)
3. **Base measures**: Common aggregations (sum, average, count)
4. **Business metrics**: Pre-defined calculations (e.g., conversion rates, lift percentages)
5. **Synonyms**: Alternative names to improve natural language understanding

**Best Practices**:

- Use clear, business-friendly names and descriptions
- Add synonyms for common variations (e.g., "customer_id", "customer", "cust_id")
- Include sample values for categorical dimensions
- Define calculated dimensions for common transformations (date parts, ranges)
- Create filtered measures for segment-specific metrics (e.g., holiday vs non-holiday)
- Use custom measures for complex calculations (correlations, percentages)

### Step 3: Create Topic Files

Create **one topic per view** in `semantics/topics/`. The topic should:

1. Reference the corresponding view
2. Describe the business domain
3. List the key questions it can answer (as comments)

```yaml
name: retail_analytics
description: "Comprehensive retail analytics covering sales, seasonality, and economic factors"
base_view: store_sales
views:
  - store_sales
# Questions this topic can answer:
# - Which stores have the highest sales?
# - How do holidays impact revenue?
# - What seasonal patterns exist in the data?
```

### Step 4: Validate Configuration

```bash
oxy build
```
This converts the oxy files to cube syntax. Unlike other objects, `oxy validate` does not work here.

### Running the Semantic Engine

Start the semantic engine server to enable deterministic query generation:

```bash
# Start with default settings
oxy semantic-engine

# Start in development mode with hot reloading
oxy semantic-engine --dev-mode

# Customize port and logging
oxy semantic-engine --port 4000 --log-level debug
```

The semantic engine serves the semantic layer via Cube.js API.

### Using Semantic Layer in Agents

Reference the semantic layer in agent tools:

```yaml
tools:
  - type: semantic_query
    name: query_sales_data
    description: Query sales data using semantic layer
    topic: sales
```

Agents can then query using business terms defined in your views:

- "What are the total sales by store?"
- "Show me the holiday sales lift percentage"
- "Which stores are underperforming?"

The semantic engine automatically translates these to correct SQL based on your view definitions.

### Common Patterns

#### Pattern 1: Time-Based Dimensions

Extract date parts for temporal analysis:

```yaml
dimensions:
  - name: year
    type: number
    expr: "EXTRACT(YEAR FROM order_date)"

  - name: month
    type: number
    expr: "EXTRACT(MONTH FROM order_date)"

  - name: quarter
    type: number
    expr: "EXTRACT(QUARTER FROM order_date)"
```

#### Pattern 2: Categorical Ranges

Bin continuous values into categories:

```yaml
dimensions:
  - name: price_range
    type: string
    expr: |
      CASE
        WHEN price < 100 THEN 'Budget'
        WHEN price BETWEEN 100 AND 500 THEN 'Mid-Range'
        ELSE 'Premium'
      END
    samples: ["Budget", "Mid-Range", "Premium"]
```

#### Pattern 3: Comparison Metrics

Calculate percentage differences or lifts:

```yaml
measures:
  - name: growth_rate
    type: custom
    expr: |
      (SUM(CASE WHEN year = 2024 THEN revenue END) -
       SUM(CASE WHEN year = 2023 THEN revenue END)) /
       SUM(CASE WHEN year = 2023 THEN revenue END) * 100
    description: "Year-over-year growth rate percentage"
```

#### Pattern 4: Correlation Analysis

Built-in statistical measures:

```yaml
measures:
  - name: temp_sales_correlation
    type: custom
    expr: "CORR(temperature, sales)"
    description: "Correlation between temperature and sales (-1 to 1)"
```

### Troubleshooting Semantic Layer

1. **View not found error**

   - Ensure `.view.yml` files are in `semantics/views/` directory
   - Check view name matches exactly in topic file
   - Run `oxy validate` to check for syntax errors

2. **Dimension/measure not recognized**

   - Verify the name is spelled correctly
   - Check that `expr` field uses valid SQL for your database dialect
   - Ensure table columns referenced in `expr` exist

3. **Semantic engine won't start**

   - Check port is not already in use: `lsof -i :4000`
   - Verify database connections in `config.yml`
   - Review logs with `--log-level debug`

4. **SQL generation errors**
   - Review dimension/measure `expr` for SQL syntax errors
   - Ensure data types match (e.g., don't use `SUM` on string fields)
   - Test expressions in isolation with `oxy run query.sql --dry-run`

### Semantic Layer File Discovery

```bash
# List all view files
find semantics/views -name "*.view.yml"

# List all topic files
find semantics/topics -name "*.topic.yml"

# Validate semantic layer files
oxy validate
```

## Example Workflows

### Example 1: Test a New Agent

```bash
# Discover agents
find . -name "*.agent.yml"

# Test specific agent
oxy run analysis-agent.agent.yml "Summarize last quarter"
```

### Example 2: Run Parameterized SQL Query

```bash
# Discover SQL files
find . -name "*.sql" -not -path "*/.*"

# Run with parameters
oxy run reports/monthly.sql -v year=2024 -v month=12
```

### Example 3: Validate Before Running

```bash
# Validate configuration
oxy validate

# Test SQL file with dry-run
oxy run data-pipeline.sql --dry-run

# Run workflow
oxy run data-pipeline.workflow.yml
```

## Integration with Claude Code

When Claude Code is testing Oxy assets:

1. **Always validate first**: `oxy validate`
2. **Discover files**: Use `find` commands to see what's available
3. **Use direct oxy commands** for all operations
4. **Test incrementally**: Test individual files before bulk testing
5. **Check for variables**: Look for `{{ }}` in SQL files before running
6. **Use dry-run for SQL**: Always test SQL queries with `--dry-run` before executing


## Best Practices

1. **Use descriptive file names**: `sales-analysis.agent.yml` > `agent1.agent.yml`
2. **Document SQL variables**: Add comments explaining required variables
3. **Test incrementally**: Validate → Test SQL → Test workflows → Test agents
4. **Use dry-run**: Always dry-run SQL before executing against production
5. **Version control**: Commit working queries to verified folders

## Additional Resources

- Oxy Documentation: <https://github.com/oxy-hq/oxy>
- Oxy CLI Help: `oxy --help`

## DeepWiki Documentation (Fallback)

If you encounter Oxy features or behaviors not documented in this guide, use DeepWiki as a fallback resource:

**URL**: <https://deepwiki.com/oxy-hq/oxy>

**When to use DeepWiki**:

1. You encounter an Oxy error message not covered in Troubleshooting
2. You need to understand advanced Oxy features or configuration options
3. You're unsure about Oxy command syntax or parameters
4. You need examples of specific Oxy patterns not documented here

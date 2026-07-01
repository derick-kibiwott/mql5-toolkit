<p align="center">
  <h1 align="center">MQL5 Toolkit</h1>
  <p align="center">
    A professional collection of reusable MQL5 components, Expert Advisors, Indicators, Scripts, and documentation for building robust algorithmic trading systems.
  </p>
</p>

---

## Vision

**MQL5 Toolkit** is a long-term project focused on building a clean, reusable, and well-documented codebase for MQL5 development.

The primary goals are to:

- Build production-quality Expert Advisors, Indicators, and Scripts
- Create reusable object-oriented components
- Minimize duplicated code through modular design
- Document every project thoroughly
- Apply professional software engineering practices to algorithmic trading
- Serve as both a personal knowledge base and an open-source learning resource

---

## Repository Structure

```
mql5-toolkit/
│
├── README.md
├── LICENSE
├── CHANGELOG.md
│
├── docs/
│   ├── architecture.md
│   ├── coding-style.md
│   ├── trading-concepts/
│   ├── indicators/
│   ├── expert-advisors/
│   └── scripts/
│
├── include/
│   ├── common/
│   ├── indicators/
│   ├── risk/
│   ├── strategy/
│   ├── time/
│   ├── trading/
│   └── utilities/
│
├── indicators/
│   ├── ema-crossover/
│   │   ├── EMA_Crossover_Indicator.mq5
│   │   ├── README.md
│   │   ├── images/
│   │   └── examples/
│   │
│   └── ...
│
├── expert-advisors/
│   ├── ema-crossover/
│   │   ├── EMA_Crossover_EA.mq5
│   │   ├── README.md
│   │   ├── backtests/
│   │   ├── presets/
│   │   └── images/
│   │
│   └── ...
│
├── scripts/
│   ├── close-all-positions/
│   │   ├── Close_All_Positions.mq5
│   │   └── README.md
│   │
│   └── ...
│
├── tests/
│
└── assets/
    ├── images/
    ├── diagrams/
    └── icons/
```

---

## Folder Overview

### `docs/`

Contains all project documentation.

Examples include:

- Architecture
- Coding standards
- Trading concepts
- Design decisions
- Development guides
- Strategy documentation

---

### `include/`

Contains reusable MQL5 classes and libraries.

Only reusable code belongs here.

Examples:

- Indicator wrappers
- Trade management
- Risk management
- Logging
- Utility classes
- Time helpers
- Common types

> **Rule:** Nothing inside `include/` should depend on a specific Expert Advisor, Indicator, or Script.

---

### `indicators/`

Contains complete custom indicators.

Each indicator lives in its own directory together with its documentation and supporting resources.

Example:

```
indicators/
└── ema-crossover/
    ├── EMA_Crossover_Indicator.mq5
    ├── README.md
    ├── images/
    └── examples/
```

---

### `expert-advisors/`

Contains complete automated trading systems.

Each Expert Advisor has its own directory containing:

- Source code
- Documentation
- Backtests
- Presets
- Images

---

### `scripts/`

Contains standalone MQL5 scripts.

Examples:

- Close positions
- Delete chart objects
- Export history
- Utility tools

---

### `tests/`

Contains experimental code and testing projects.

Examples:

- Class testing
- Performance testing
- Indicator validation
- Prototype implementations

---

### `assets/`

Contains repository-wide resources used by documentation.

Examples:

- Screenshots
- Diagrams
- Icons
- Illustrations

---

## Architecture

The toolkit follows a layered architecture.

```
MQL5 Standard Library
         |
         v
 Reusable Classes (include/)
         |
         v
Expert Advisors • Indicators • Scripts
```

Applications depend on reusable classes. Reusable classes never depend on applications.

---

## Design Principles

The toolkit follows modern software engineering principles.

| Principle                   | Description                                |
| --------------------------- | ------------------------------------------ |
| Object-Oriented Programming | Encapsulation and abstraction              |
| Single Responsibility       | Each class has one clear purpose           |
| Separation of Concerns      | Logic is divided into distinct sections    |
| Code Reusability            | Components are built for multiple contexts |
| Readability                 | Code is easy to understand at a glance     |
| Maintainability             | Structure supports long-term evolution     |
| Self-documenting            | Intent is clear from naming and structure  |

---

## Naming Conventions

### Repository

Use lowercase with hyphens.

```
mql5-toolkit
```

---

### Folders

Use lowercase with hyphens.

```
expert-advisors
ema-crossover
close-all-positions
```

---

### MQL5 Files

Use descriptive PascalCase with underscores.

```
EMA_Crossover_EA.mq5
EMA_Crossover_Indicator.mq5
Close_All_Positions.mq5
```

---

### Classes

Use PascalCase.

```cpp
class EMA
class TradeManager
class BarDetector
```

---

### Methods

Use camelCase.

```cpp
update()
getSignal()
hasOpenPosition()
```

---

### Variables

Use snake_case.

```cpp
fast_period
stop_loss
take_profit
```

---

### Private Members

Use snake_case with a trailing underscore.

```cpp
period_
handle_
buffer_
magic_number_
```

---

### Enumerations

Use PascalCase.

```cpp
enum Signal
{
    Buy,
    Sell,
    None
};
```

---

## Documentation Standard

Every project must contain a `README.md`.

A typical project README should include:

- Overview
- Purpose
- Features
- Inputs
- Outputs
- Architecture
- Algorithm
- Class Diagram
- Usage
- Screenshots
- Future Improvements
- Changelog

---

## Development Workflow

Each project follows the same workflow.

1. Research the trading idea
2. Design the architecture
3. Build reusable components
4. Develop the indicator (if applicable)
5. Develop the Expert Advisor or Script
6. Test thoroughly
7. Optimize performance
8. Document the project
9. Publish

---

## Coding Philosophy

The goal is to write code that is easy to understand years later.

Every class should:

- Have one clear responsibility
- Hide implementation details
- Expose a clean public interface
- Be reusable in multiple projects

When writing new code, always ask:

> **Will I use this again in another project?**

If the answer is **yes**, it probably belongs inside the `include/` directory.

---

## Project Status

This toolkit is under active development.

New components, utilities, strategies, and documentation will be added continuously.

---

## License

Licensed under the MIT License.

---

## Author

**Derick Kibiwott**

Algorithmic Trading • MQL5 Development • Object-Oriented Programming

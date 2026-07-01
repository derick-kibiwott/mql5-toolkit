# EMA Crossover Indicator

## Purpose

Plots two EMAs and detects crossover points.

## Features

- Fast EMA
- Slow EMA
- Buy crossover detection
- Sell crossover detection

## Inputs

| Name            | Description            |
| --------------- | ---------------------- |
| Fast EMA Period | Period of the fast EMA |
| Slow EMA Period | Period of the slow EMA |

## How it works

1. Creates two EMA handles.
2. Updates both on every calculation.
3. Detects crossovers.
4. Draws signals.

## Class Diagram

EMA
↓
EMACrossoverStrategy

## Future Improvements

- Alerts
- Push notifications
- Multi-timeframe support

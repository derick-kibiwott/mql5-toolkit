//+------------------------------------------------------------------+
//|                                                           EA.mq5 |
//|                                  Copyright 2026, Derick Kibiwott |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Derick Kibiwott"
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include <Trade\Trade.mqh>

// Adding input groups for better organization in the MetaTrader 5 interface
input group "Strategy Settings";
input int InpFastEMAPeriod = 9;  // Fast EMA Period
input int InpSlowEMAPeriod = 21; // Slow EMA Period

input group "Risk Management";
input double InpLotSize = 0.1;       // Trade Volume (Lots)
input int InpStopLoss = 1500;        // Stop Loss (Points)
input int InpTakeProfit = 3000;      // Take Profit (Points)
input ulong InpMagicNumber = 888111; // Expert Magic Number

class BarDetector
{
  private:
    datetime last_bar_time_; // Variable to store the time of the last detected bar

  public:
    // Constructor to initialize the last bar time
    BarDetector() : last_bar_time_(0) {};

    // Method to check if a new bar has formed
    bool isNewBar()
    {
        datetime current_bar_time = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);

        // Check if the current bar time is different from the last recorded bar time
        if (current_bar_time != last_bar_time_)
        {
            last_bar_time_ = current_bar_time;
            return true;
        }
        // If the bar time hasn't changed, return false
        return false;
    };
};

class EMAIndicator
{
  private:
    int period_;
    int handle_;
    double values_[];

  public:
    // Constructor to initialize the EMA indicator with a specified period
    EMAIndicator(int period) : period_(period)
    {
        handle_ = iMA(_Symbol, _Period, period_, 0, MODE_EMA, PRICE_CLOSE);
        ArrayResize(values_, 3); // Resize the array to hold 3 values (current, last closed, two candles ago)
        ArraySetAsSeries(values_, true);
    };

    // Method to update the EMA values
    bool update()
    {
        int copied = CopyBuffer(handle_, 0, 0, 3, values_);
        return copied == 3;
    };

    // Method to retrieve the EMA value at a specific index
    double get(int index) const
    {
        return values_[index];
    };

    void release()
    {
        if (handle_ != INVALID_HANDLE)
        {
            IndicatorRelease(handle_);
            handle_ = INVALID_HANDLE;
        }
    };

    ~EMAIndicator()
    {
        release();
    }
};

enum Signal
{
    Buy,
    Sell,
    None
};

class EMACrossoverStrategy
{
  private:
    EMAIndicator fast_ema_;
    EMAIndicator slow_ema_;

  public:
    // Constructor to initialize the crossover strategy with specified fast and slow EMA periods
    EMACrossoverStrategy(int fast_period, int slow_period) : fast_ema_(fast_period), slow_ema_(slow_period) {};

    // Method to determine the trading signal based on EMA crossover
    Signal getSignal()
    {
        bool fast_updated = fast_ema_.update();
        bool slow_updated = slow_ema_.update();

        if (!fast_updated || !slow_updated)
        {
            return Signal::None;
        }
        bool buy_signal = fast_ema_.get(1) > slow_ema_.get(1) && fast_ema_.get(2) <= slow_ema_.get(2);

        bool sell_signal = fast_ema_.get(1) < slow_ema_.get(1) && fast_ema_.get(2) >= slow_ema_.get(2);

        if (buy_signal)
        {
            return Signal::Buy;
        }

        if (sell_signal)
        {
            return Signal::Sell;
        }

        return Signal::None;
    };
};

class TradeManager
{
  private:
    CTrade trade_;
    ulong magic_number_;

  public:
    // Constructor to initialize the TradeManager with a specified magic number
    TradeManager(ulong magic_number) : magic_number_(magic_number)
    {
        trade_.SetExpertMagicNumber(magic_number_);
    };

    bool hasOpenPosition() const
    {
        int total_positions = PositionsTotal();
        for (int i = 0; i < total_positions; i++)
        {
            ulong ticket = PositionGetTicket(i);

            if (!PositionSelectByTicket(ticket))
            {
                continue;
            }

            ulong position_magic = PositionGetInteger(POSITION_MAGIC);
            string position_symbol = PositionGetString(POSITION_SYMBOL);

            if (position_magic == magic_number_ && position_symbol == _Symbol)
            {
                return true;
            }
        }

        return false;
    };

    bool buy(double lot_size, int stop_loss_points, int take_profit_points)
    {
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double stop_loss = ask - stop_loss_points * _Point;
        double take_profit = ask + take_profit_points * _Point;
        return trade_.Buy(lot_size, _Symbol, ask, stop_loss, take_profit, "EMA Crossover Buy");
    };

    bool sell(double lot_size, int stop_loss_points, int take_profit_points)
    {

        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double stop_loss = bid + stop_loss_points * _Point;
        double take_profit = bid - take_profit_points * _Point;
        return trade_.Sell(lot_size, _Symbol, bid, stop_loss, take_profit, "EMA Crossover Sell");
    };
};

BarDetector bar_detector;
EMACrossoverStrategy strategy(InpFastEMAPeriod, InpSlowEMAPeriod);
TradeManager trade_manager(InpMagicNumber);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("-------------------- EA initialized --------------------");
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("-------------------- EA deinitialized --------------------");
    Print("DEINIT REASON: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 1. Wait for a new candle to form
    if (!bar_detector.isNewBar())
    {
        return; // Exit if no new bar has formed
    }

    // 2. Ask the strategy for a signal (buy, sell, or none)
    Signal signal = strategy.getSignal();

    // 3. Ignore if the signal is none or if there is already an open position
    if (signal == Signal::None || trade_manager.hasOpenPosition())
    {
        return; // Exit if no valid signal or position is already open
    }

    //   4. Execute the trade based on the signal

    if (signal == Signal::Buy)
    {
        trade_manager.buy(InpLotSize, InpStopLoss, InpTakeProfit);
    }
    else if (signal == Signal::Sell)
    {
        trade_manager.sell(InpLotSize, InpStopLoss, InpTakeProfit);
    }
}
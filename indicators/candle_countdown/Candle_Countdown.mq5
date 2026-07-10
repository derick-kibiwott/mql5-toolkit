//+------------------------------------------------------------------+
//|                                             Candle_Countdown.mq5 |
//|                                  Copyright 2026, Derick Kibiwott |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Derick Kibiwott"
#property link "https://www.mql5.com"
#property version "1.00"
#property description "Displays a live countdown timer for the active candle, updating every second until the bar closes. The timer follows the current bid price, remains offset from the forming candle for improved visibility, and automatically formats the remaining time based on the active timeframe."

#include "../../include/time/Bar_Detector.mqh"

#property indicator_chart_window
#property indicator_plots 0

//--- Inputs
input int inp_x_offset = 2;  // X-axis offset
input int inp_y_offset = 18; // Y-axis offset
input int inp_font_size = 8; // Font size
input color inp_countdown_label_color = clrMidnightBlue;

const long CURRENT_CHART = 0;
const int MAIN_WINDOW = 0;
const int POINT_INDEX = 0;
const int CANDLE_SHIFT = 0;

class CountdownLabel
{
  private:
    string name_;

    static const int FONT_SIZE_;
    static const int X_OFFSET_CHART_SHIFT_;
    static const int X_OFFSET_CHART_SHIFT_OFF_;
    static const int Y_OFFSET_;
    static const color COUNTDOWN_LABEL_COLOR_;

  public:
    CountdownLabel(const string &name) : name_(name) {};
    bool create()
    {
        datetime current_bar = iTime(_Symbol, _Period, CANDLE_SHIFT);
        double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        bool success = ObjectCreate(CURRENT_CHART, name_, OBJ_LABEL, MAIN_WINDOW, 0, 0);

        if (!success)
        {
            Print("Failed to create label: ", name_);
            return false;
        }

        ObjectSetInteger(CURRENT_CHART, name_, OBJPROP_FONTSIZE, FONT_SIZE_);
        ObjectSetInteger(CURRENT_CHART, name_, OBJPROP_COLOR, COUNTDOWN_LABEL_COLOR_);
        ObjectSetInteger(CURRENT_CHART, name_, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
        ObjectSetInteger(CURRENT_CHART, name_, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

        setXCoord();
        ObjectSetString(CURRENT_CHART, name_, OBJPROP_TEXT, "00:00");

        return true;
    }

    bool setXCoord()
    {

        bool chart_shifted = ChartGetInteger(CURRENT_CHART, CHART_SHIFT, MAIN_WINDOW);
        int x_offset = chart_shifted ? X_OFFSET_CHART_SHIFT_ : X_OFFSET_CHART_SHIFT_OFF_;

        return ObjectSetInteger(CURRENT_CHART, name_, OBJPROP_XDISTANCE, x_offset);
    }

    bool trackPrice()
    {
        int x, y;
        datetime current_bar_open_time = iTime(_Symbol, _Period, CANDLE_SHIFT);
        double current_bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        if (ChartTimePriceToXY(CURRENT_CHART, MAIN_WINDOW, current_bar_open_time, current_bid_price, x, y))
        {
            setXCoord();
            return ObjectSetInteger(CURRENT_CHART, name_, OBJPROP_YDISTANCE, y - Y_OFFSET_);
        }

        return false;
    }

    bool setText(const string text) const
    {
        return ObjectSetString(CURRENT_CHART, name_, OBJPROP_TEXT, text);
    }

    bool destroy()
    {
        return ObjectDelete(CURRENT_CHART, name_);
    }
};

const int CountdownLabel::X_OFFSET_CHART_SHIFT_ = inp_x_offset;
const int CountdownLabel::X_OFFSET_CHART_SHIFT_OFF_ = inp_x_offset * 40;
const int CountdownLabel::Y_OFFSET_ = inp_y_offset;
const color CountdownLabel::COUNTDOWN_LABEL_COLOR_ = inp_countdown_label_color;

const int CountdownLabel::FONT_SIZE_ = inp_font_size;

class BrokerClock
{
  private:
    long offset_seconds_;

  public:
    BrokerClock() : offset_seconds_(0) {};

    void synchronize()
    {
        offset_seconds_ = (long)(TimeCurrent() - TimeLocal());
    }

    datetime now() const
    {
        return TimeLocal() + offset_seconds_;
    }
};

class CandleCountdown
{
  private:
    CountdownLabel label_;
    BrokerClock broker_clock_;
    datetime close_time_;
    BarDetector bar_detector_;

  public:
    CandleCountdown() : label_("CandleCountdown") {};

    bool create()
    {
        broker_clock_.synchronize();
        setCloseTime();
        return label_.create();
    }
    bool update()
    {

        label_.trackPrice();

        if (bar_detector_.isNewBar())
        {
            setCloseTime();
        }

        if (label_.setText(formatTime()))
        {

            return true;
        }

        return false;
    };

    void synchronizeClock()
    {
        broker_clock_.synchronize();
    }

    void destroy()
    {
        if (!label_.destroy())
        {
            Print("Failed to delete countdown label.");
        }
    };

  private:
    int remainingSeconds() const
    {
        return (int)(close_time_ - broker_clock_.now());
    };

    string formatTime() const
    {
        const int remaining_seconds = MathMax(0, remainingSeconds());

        static const int SECONDS_PER_MINUTE = 60;
        static const int SECONDS_PER_HOUR = 60 * SECONDS_PER_MINUTE;
        static const int SECONDS_PER_DAY = 24 * SECONDS_PER_HOUR;
        static const int SECONDS_PER_WEEK = 7 * SECONDS_PER_DAY;

        int remaining = remaining_seconds;

        const int weeks = remaining / SECONDS_PER_WEEK;
        remaining %= SECONDS_PER_WEEK;

        const int days = remaining / SECONDS_PER_DAY;
        remaining %= SECONDS_PER_DAY;

        const int hours = remaining / SECONDS_PER_HOUR;
        remaining %= SECONDS_PER_HOUR;

        const int minutes = remaining / SECONDS_PER_MINUTE;
        const int seconds = remaining % SECONDS_PER_MINUTE;

        switch (_Period)
        {

        case PERIOD_MN1: {
            return StringFormat("%02d:%02d:%02d:%02d:%02d", weeks, days, hours, minutes, seconds);
        }

        case PERIOD_D1:
        case PERIOD_W1: {
            return StringFormat("%02d:%02d:%02d:%02d", days, hours, minutes, seconds);
        }

        case PERIOD_H1:
        case PERIOD_H4: {
            return StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
        }

        default: {
            return StringFormat("%02d:%02d", minutes, seconds);
        }

            // end case
        }
    }

    void setCloseTime()
    {
        datetime open = iTime(_Symbol, _Period, CANDLE_SHIFT);
        close_time_ = open + PeriodSeconds(_Period);
    }
};

CandleCountdown candle_countdown;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    if (!candle_countdown.create())
    {
        return INIT_FAILED;
    }
    EventSetTimer(1);
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
void OnTimer()
{
    candle_countdown.update();
    ChartRedraw(CURRENT_CHART);
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[])
{

    candle_countdown.synchronizeClock();
    return (rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    candle_countdown.destroy();
}
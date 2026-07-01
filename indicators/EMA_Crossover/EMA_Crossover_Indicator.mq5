//+------------------------------------------------------------------+
//|                                      EMA_Crossover_Indicator.mq5 |
//|                                  Copyright 2026, Derick Kibiwott |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2026, Derick Kibiwott"
#property link "https://www.mql5.com"
#property description "Plots fast and slow Exponential Moving Averages (EMAs) and provides the foundation for EMA crossover signal detection."
#property version "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

//  Fast EMA
#property indicator_label1 "Fast EMA"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2

//  Slow EMA
#property indicator_label2 "Slow EMA"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrCrimson
#property indicator_style2 STYLE_SOLID
#property indicator_width2 2

//  Indicator Settings
input group "Indicator Settings";
input int inp_fast_period = 9;  // Fast EMA Period
input int inp_slow_period = 21; // Slow EMA Period

//  Create buffers for the indicators
double fast_buffer[];
double slow_buffer[];

//  Indicator handles
int fast_handle;
int slow_handle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    fast_handle = iMA(_Symbol, _Period, inp_fast_period, 0, MODE_EMA, PRICE_CLOSE);
    slow_handle = iMA(_Symbol, _Period, inp_slow_period, 0, MODE_EMA, PRICE_CLOSE);

    //  Check if the handles are valid
    if (fast_handle == INVALID_HANDLE || slow_handle == INVALID_HANDLE)
    {
        Print("Failed to create one or more EMA indicator handles.");
        return INIT_FAILED;
    }

    SetIndexBuffer(0, fast_buffer, INDICATOR_DATA);
    SetIndexBuffer(1, slow_buffer, INDICATOR_DATA);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
    // Determine how many bars need to be calculated
    int to_copy = rates_total;

    if (prev_calculated > 0)
    {
        // If we already have calculated data, we only need to update the last bar
        to_copy = rates_total - prev_calculated + 1;
    }

    // Copy only the required bars from the built-in indicator handles
    if (CopyBuffer(fast_handle, 0, 0, to_copy, fast_buffer) < 0)
        return 0;
    if (CopyBuffer(slow_handle, 0, 0, to_copy, slow_buffer) < 0)
        return 0;

    return (rates_total);
}

void OnDeinit(const int reason)
{
    if (fast_handle != INVALID_HANDLE)
    {
        IndicatorRelease(fast_handle);
    }
    if (slow_handle != INVALID_HANDLE)
    {
        IndicatorRelease(slow_handle);
    }
}
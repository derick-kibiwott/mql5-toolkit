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

input group "Indicator Settings";
input int InpFastEMAPeriod = 9;  // Fast EMA Period
input int InpSlowEMAPeriod = 21; // Slow EMA Period

class EMA
{
  private:
    int period_;
    int handle_;
    double buffer_[];

  public:
    EMA(int period) : period_(period)
    {
        handle_ = iMA(_Symbol, _Period, period_, 0, MODE_EMA, PRICE_CLOSE);

        ArrayResize(buffer_, 3);
        ArraySetAsSeries(buffer_, true);
    }

    bool update()
    {
        int copied = CopyBuffer(handle_, 0, 0, 3, buffer_);

        return copied == 3;
    }

    double get(int index) const
    {
        return buffer_[index];
    }

    bool isValid() const
    {
        return handle_ != INVALID_HANDLE;
    }
};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
    return rates_total;
}
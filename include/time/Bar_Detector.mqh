//+------------------------------------------------------------------+
//|                                                Bar_Detector.mqh  |
//|                                  Copyright 2026, Derick Kibiwott |
//+------------------------------------------------------------------+
#ifndef BAR_DETECTOR_MQH
#define BAR_DETECTOR_MQH

class BarDetector
{
  private:
    datetime last_bar_time_;

  public:
    BarDetector() : last_bar_time_(0)
    {
    }

    bool isNewBar()
    {
        datetime current_bar_time = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);

        if (current_bar_time != last_bar_time_)
        {
            last_bar_time_ = current_bar_time;
            return true;
        }

        return false;
    }
};

#endif // BAR_DETECTOR_MQH
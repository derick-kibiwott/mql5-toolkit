//+------------------------------------------------------------------+
//|                                                Bar_Detector.mqh  |
//|                                  Copyright 2026, Derick Kibiwott |
//+------------------------------------------------------------------+
#ifndef BAR_DETECTOR_MQH
#define BAR_DETECTOR_MQH

class BarDetector
{
  private:
    datetime last_bar_opening_time_;

  public:
    BarDetector() : last_bar_opening_time_(0) {};

    bool isNewBar()
    {
        long current_bar_opening_time_value;
        ResetLastError();

        if (!SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE, current_bar_opening_time_value))
        {
            PrintFormat("Failed to retrieve the latest bar opening time. Error: %d", GetLastError());

            return false;
        }

        datetime current_bar_opening_time = (datetime)current_bar_opening_time_value;

        // First successful observation.
        // Initialize state without signalling a new bar.
        if (last_bar_opening_time_ == 0)
        {
            last_bar_opening_time_ = current_bar_opening_time;
            return false;
        }

        if (current_bar_opening_time < last_bar_opening_time_)
        {
            Print("BarDetector detected a regression in bar time. "
                  "Resetting internal state.");

            last_bar_opening_time_ = current_bar_opening_time;
            return false;
        }

        if (current_bar_opening_time > last_bar_opening_time_)
        {
            last_bar_opening_time_ = current_bar_opening_time;
            return true;
        }

        return false;
    }
};

#endif // BAR_DETECTOR_MQH
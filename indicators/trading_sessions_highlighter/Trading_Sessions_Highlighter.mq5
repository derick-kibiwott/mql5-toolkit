//+------------------------------------------------------------------+
//| Trading_Sessions.mq5 | | Copyright
// 2026, Derick Kibiwott | |
// https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Derick Kibiwott"
#property link "https://www.mql5.com"
#property version "1.00"
#property description "This indicator highlights the Sydney, Tokyo, London and New York sessions."

#property indicator_chart_window
#property indicator_plots 0

enum DST_REGION
{
    DST_NONE,     // None
    DST_USA,      // USA
    DST_EUROPE,   // Europe
    DST_AUSTRALIA // Australia
};

enum ENUM_DAYS_BACK
{
    ONE_DAY = 1,    // 1 Day
    ONE_WEEK = 7,   // 1 Week
    ONE_MONTH = 30, // 1 Month
    ALL_TIME = -1   // All Time
};

enum WINTER_UTC_OFFSET
{
    SYDNEY_WINTER_UTC_OFFSET = 10,  // Sydney
    TOKYO_WINTER_UTC_OFFSET = 9,    // Tokyo
    LONDON_WINTER_UTC_OFFSET = 0,   // London
    NEWYORK_WINTER_UTC_OFFSET = -5, // New york
    ZERO_WINTER_UTC_OFFSET = 0      // UTC
};

input group "Broker Time";
input DST_REGION inp_broker_dst = DST_NONE;                             // Broker daylight saving time
input WINTER_UTC_OFFSET inp_broker_local_time = ZERO_WINTER_UTC_OFFSET; // Broker local time

input group "Sessions Settings";
input bool inp_show_sydney = true;  // Show Sydney
input bool inp_show_tokyo = true;   // Show Tokyo
input bool inp_show_london = true;  // Show London
input bool inp_show_newyork = true; // Show Newyork

input group "Sydney Session Settings";
input color inp_sydney_session_color = clrLightPink; // Color

input group "Tokyo Session Settings";
input color inp_tokyo_session_color = clrLightGreen; // Color

input group "London Session Settings";
input color inp_london_session_color = clrLightSkyBlue; // Color

input group "Newyork Session Settings";
input color inp_newyork_session_color = clrLightCoral; // Color

input group "History";
input ENUM_DAYS_BACK inp_days_back = ALL_TIME; // Days back

const int SECONDS_IN_A_MINUTE = 60;
const int SECONDS_IN_AN_HOUR = 60 * SECONDS_IN_A_MINUTE;
const int SECONDS_IN_A_DAY = 24 * SECONDS_IN_AN_HOUR;

const int CURRENT_CHART = 0;
const int WINDOW_INDEX = 0;

enum SESSION_HOUR_DURATION
{
    SYDNEY_SESSION_DURATION = 9,
    TOKYO_SESSION_DURATION = 9,
    LONDON_SESSION_DURATION = 9,
    NEWYORK_SESSION_DURATION = 9
};

enum SESSIONS
{
    SYDNEY_SESSION,
    TOKYO_SESSION,
    LONDON_SESSION,
    NEWYORK_SESSION
};

enum SUNDAY_OCCURRENCE
{
    FIRST = 1,
    SECOND = 2,
    THIRD = 3,
    FOURTH = 4,
    LAST = 5
};

struct DST_RULE
{
    int start_month;
    SUNDAY_OCCURRENCE start_occurrence;
    int start_hour_utc;
    bool start_previous_day;

    int end_month;
    SUNDAY_OCCURRENCE end_occurrence;
    int end_hour_utc;
    bool end_previous_day;

    bool crosses_year;

    int start_minute;
    int end_minute;

    // DST_RULE(int _start_month, SUNDAY_OCCURRENCE _start_occurrence, int _start_hour_utc, bool _start_previous_day, int _end_month, SUNDAY_OCCURRENCE _end_occurrence,
    //          int _end_hour_utc, bool _end_previous_day, bool _crosses_year, int _start_minute, int _end_minute)
    // {
    //     start_month = _start_month;
    //     start_occurrence = _start_occurrence;
    //     start_hour_utc = _start_hour_utc;
    //     start_previous_day = _start_previous_day;
    //     end_month = _end_month;
    //     end_occurrence = _end_occurrence;
    //     end_hour_utc = _end_hour_utc;
    //     end_previous_day = _end_previous_day;
    //     crosses_year = _crosses_year;
    //     start_minute = _start_minute;
    //     end_minute = _start_minute;
    // }
};

struct SESSION_INFO
{
    SESSIONS session;

    int open_hour;
    int open_minute;
    SESSION_HOUR_DURATION session_hour_duration;

    DST_REGION dst_region;

    DST_RULE dst_rule;
    WINTER_UTC_OFFSET winter_utc_offset;

    SESSION_INFO(SESSIONS _session, int _open_hour, int _open_minute, SESSION_HOUR_DURATION _session_hour_duration, DST_REGION _dst_region, const DST_RULE &_dst_rule,
                 WINTER_UTC_OFFSET _winter_utc_offset)
        : dst_rule(_dst_rule)
    {
        session = _session;
        open_hour = _open_hour;
        open_minute = _open_minute;
        session_hour_duration = _session_hour_duration;
        dst_region = _dst_region;
        winter_utc_offset = _winter_utc_offset;
    }
};

const DST_RULE AUSTRALIA_DST_RULE = {10, FIRST, 16, true, 4, FIRST, 16, true, true};
const DST_RULE EUROPE_DST_RULE = {3, LAST, 1, false, 10, LAST, 1, false, false};
const DST_RULE USA_DST_RULE = {3, SECOND, 7, false, 11, FIRST, 6, false, false};
const DST_RULE NO_DST_RULE = {0, FIRST, 0, false, 0, FIRST, 0, false, false};

const SESSION_INFO SYDNEY_SESSION_INFO(SYDNEY_SESSION, 22, 0, SYDNEY_SESSION_DURATION, DST_AUSTRALIA, AUSTRALIA_DST_RULE, SYDNEY_WINTER_UTC_OFFSET);
const SESSION_INFO TOKYO_SESSION_INFO(TOKYO_SESSION, 0, 0, TOKYO_SESSION_DURATION, DST_NONE, NO_DST_RULE, TOKYO_WINTER_UTC_OFFSET);
const SESSION_INFO LONDON_SESSION_INFO(LONDON_SESSION, 8, 0, LONDON_SESSION_DURATION, DST_EUROPE, EUROPE_DST_RULE, LONDON_WINTER_UTC_OFFSET);
const SESSION_INFO NEWYORK_SESSION_INFO(NEWYORK_SESSION, 13, 0, NEWYORK_SESSION_DURATION, DST_USA, USA_DST_RULE, NEWYORK_WINTER_UTC_OFFSET);

//+------------------------------------------------------------------+
//| Class SessionDST
//+------------------------------------------------------------------+

class SessionDST
{
  public:
    bool isDSTActive(datetime utc_time, const DST_RULE &dst_rule)
    {
        MqlDateTime input_time_struct = {};
        TimeToStruct(utc_time, input_time_struct);

        int this_year = input_time_struct.year;

        if (!dst_rule.crosses_year) {
            datetime dst_start_timestamp =
                getTransitionTimestamp(this_year, dst_rule.start_month, dst_rule.start_occurrence, dst_rule.start_hour_utc, dst_rule.start_minute, dst_rule.start_previous_day);

            datetime dst_end_timestamp =
                getTransitionTimestamp(this_year, dst_rule.end_month, dst_rule.end_occurrence, dst_rule.end_hour_utc, dst_rule.end_minute, dst_rule.end_previous_day);

            return (utc_time >= dst_start_timestamp && utc_time < dst_end_timestamp);
        }
        else {
            datetime dst_start_this_year_timestamp =
                getTransitionTimestamp(this_year, dst_rule.start_month, dst_rule.start_occurrence, dst_rule.start_hour_utc, dst_rule.start_minute, dst_rule.start_previous_day);
            datetime dst_end_next_year_timestamp =
                getTransitionTimestamp(this_year + 1, dst_rule.end_month, dst_rule.end_occurrence, dst_rule.end_hour_utc, dst_rule.end_minute, dst_rule.end_previous_day);

            datetime dst_start_previous_year_timestamp =
                getTransitionTimestamp(this_year - 1, dst_rule.start_month, dst_rule.start_occurrence, dst_rule.start_hour_utc, dst_rule.start_minute, dst_rule.start_previous_day);
            datetime dst_end_this_year_timestamp =
                getTransitionTimestamp(this_year, dst_rule.end_month, dst_rule.end_occurrence, dst_rule.end_hour_utc, dst_rule.end_minute, dst_rule.end_previous_day);

            return ((utc_time >= dst_start_this_year_timestamp && utc_time < dst_end_next_year_timestamp) ||
                    (utc_time >= dst_start_previous_year_timestamp && utc_time < dst_end_this_year_timestamp));
        }
    }

  private:
    datetime getTransitionTimestamp(int year, int month, SUNDAY_OCCURRENCE occurrence, int hour, int minute, bool previous_day)
    {
        MqlDateTime target_date_struct = {};

        target_date_struct.year = year;
        target_date_struct.mon = month;
        target_date_struct.day = (occurrence == 5) ? daysInMonth(year, month) : 1;
        target_date_struct.hour = hour;
        target_date_struct.min = minute;
        target_date_struct.sec = 0;

        int sunday = 0;

        datetime working_timestamp = StructToTime(target_date_struct);
        TimeToStruct(working_timestamp, target_date_struct);

        if (occurrence == LAST) {
            while (target_date_struct.day_of_week != sunday) {

                working_timestamp -= SECONDS_IN_A_DAY;
                TimeToStruct(working_timestamp, target_date_struct);
            }
        }
        else {
            int sundays_found = 0;

            while (sundays_found < (int)occurrence) {
                if (target_date_struct.day_of_week == sunday) {
                    sundays_found++;
                    if (sundays_found == (int)occurrence)
                        break;
                }
                working_timestamp += SECONDS_IN_A_DAY;
                TimeToStruct(working_timestamp, target_date_struct);
            }
        }
        if (previous_day)
            working_timestamp -= SECONDS_IN_A_DAY;

        return working_timestamp;
    }

    int daysInMonth(int year, int month)
    {
        bool leap_year = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
        int days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
        if (month == 2 && leap_year)
            return 29;

        return days[month - 1];
    }
};

//+------------------------------------------------------------------+
//| Class TimeConverter
//+------------------------------------------------------------------+

class TimeConverter : public SessionDST
{
  private:
    DST_REGION dst_region_;
    WINTER_UTC_OFFSET winter_utc_offset_;

  public:
    TimeConverter(DST_REGION dst_region, WINTER_UTC_OFFSET winter_utc_offset) : dst_region_(dst_region), winter_utc_offset_(winter_utc_offset)
    {}

    datetime getBrokerTimeInUTC(datetime server_time)
    {
        return server_time - getBrokerOffset(server_time) * SECONDS_IN_AN_HOUR;
    }
    datetime serverTimeToUTC(datetime server_time)
    {
        return server_time - winter_utc_offset_ * SECONDS_IN_AN_HOUR;
    }

    datetime UTCTimeToServer(datetime utc_time)
    {
        return utc_time + winter_utc_offset_ * SECONDS_IN_AN_HOUR;
    }

    int getBrokerOffset(datetime server_time)
    {
        datetime calculated_utc_baseline = serverTimeToUTC(server_time);

        DST_RULE selected_region_dst_region;
        bool process_rule = true;

        switch (dst_region_) {
        case DST_USA:
            selected_region_dst_region = USA_DST_RULE;
            break;

        case DST_EUROPE:
            selected_region_dst_region = EUROPE_DST_RULE;
            break;

        case DST_AUSTRALIA:
            selected_region_dst_region = AUSTRALIA_DST_RULE;
            break;

        case DST_NONE:
        default:
            process_rule = false;
            break;
        }

        bool is_dst_active = false;

        if (process_rule) {
            is_dst_active = isDSTActive(calculated_utc_baseline, selected_region_dst_region);
        }

        int dst_hour_shift = is_dst_active ? 1 : 0;

        return winter_utc_offset_ + dst_hour_shift;
    }
};

//+------------------------------------------------------------------+
//| Class SessionDrawer
//+------------------------------------------------------------------+
class SessionDrawer
{
  private:
    string prefix_;
    color sydney_session_color_;
    color tokyo_session_color_;
    color london_session_color_;
    color newyork_session_color_;

    string generateObjName(SESSIONS session, datetime start_time)
    {
        string session_str = "";

        switch (session) {
        case SYDNEY_SESSION:
            session_str = "sydney";
            break;
        case TOKYO_SESSION:
            session_str = "tokyo";
            break;
        case LONDON_SESSION:
            session_str = "london";
            break;
        case NEWYORK_SESSION:
            session_str = "newyork";
            break;
        }

        return prefix_ + session_str + TimeToString(start_time, TIME_DATE | TIME_MINUTES);
    }

  public:
    SessionDrawer(string prefix = "session") : prefix_(prefix)
    {
        sydney_session_color_ = inp_sydney_session_color;
        tokyo_session_color_ = inp_tokyo_session_color;
        london_session_color_ = inp_london_session_color;
        newyork_session_color_ = inp_newyork_session_color;
    };

    void drawSession(SESSIONS session, datetime start_time, datetime end_time)
    {
        color session_color = clrNONE;
        double top_price = ChartGetDouble(CURRENT_CHART, CHART_PRICE_MAX, WINDOW_INDEX);
        double bottom_price = ChartGetDouble(CURRENT_CHART, CHART_PRICE_MIN, WINDOW_INDEX);

        switch (session) {
        case SYDNEY_SESSION:
            session_color = sydney_session_color_;
            break;
        case TOKYO_SESSION:
            session_color = tokyo_session_color_;
            break;
        case LONDON_SESSION:
            session_color = london_session_color_;
            break;
        case NEWYORK_SESSION:
            session_color = newyork_session_color_;
            break;
        }

        string obj_name = generateObjName(session, start_time);

        ResetLastError();

        if (ObjectFind(CURRENT_CHART, obj_name) < 0) {
            if (!ObjectCreate(CURRENT_CHART, obj_name, OBJ_RECTANGLE, WINDOW_INDEX, start_time, top_price, end_time, bottom_price)) {
                Print("Failed to create session box: ", GetLastError());
            }
        }
        else {
            ObjectSetInteger(CURRENT_CHART, obj_name, OBJPROP_TIME, 0, start_time);
            ObjectSetInteger(CURRENT_CHART, obj_name, OBJPROP_TIME, 1, end_time);
        }

        ObjectSetInteger(CURRENT_CHART, obj_name, OBJPROP_COLOR, session_color);
        ObjectSetInteger(CURRENT_CHART, obj_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(CURRENT_CHART, obj_name, OBJPROP_WIDTH, 1);

        ObjectSetInteger(CURRENT_CHART, obj_name, OBJPROP_BACK, true);
        ObjectSetInteger(CURRENT_CHART, obj_name, OBJPROP_FILL, true);
        ObjectSetInteger(CURRENT_CHART, obj_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(CURRENT_CHART, obj_name, OBJPROP_HIDDEN, true);
    }

    void clearAllObjects()
    {
        ObjectsDeleteAll(CURRENT_CHART, prefix_, WINDOW_INDEX);
        ChartRedraw(CURRENT_CHART);
    }

    void redraw()
    {
        ChartRedraw(CURRENT_CHART);
    }

    ~SessionDrawer()
    {
        clearAllObjects();
    }
};

class SessionManager
{
    int number_of_bars_;
    datetime start_bar_time_;
    datetime end_bar_time_;
    datetime next_drawing_time_;
    SESSION_INFO session_;
    SessionDrawer session_drawer_;
    TimeConverter session_time_converter_;
    TimeConverter broker_time_converter_;
    bool show_session_;

  public:
    SessionManager(const SESSION_INFO &session, bool show_session)
        : session_(session), show_session_(show_session), session_time_converter_(session.dst_region, session.winter_utc_offset),
          broker_time_converter_(inp_broker_dst, inp_broker_local_time)
    {
        number_of_bars_ = inp_days_back == ALL_TIME ? iBars(_Symbol, _Period) : (inp_days_back * SECONDS_IN_A_DAY) / PeriodSeconds(_Period);

        start_bar_time_ = iTime(_Symbol, _Period, number_of_bars_);
        end_bar_time_ = iTime(_Symbol, _Period, 0);
    }

    void onInit()
    {
        datetime candle_opening_times[];
        ArrayResize(candle_opening_times, number_of_bars_);
        CopyTime(_Symbol, _Period, start_bar_time_, end_bar_time_, candle_opening_times);
        ArraySetAsSeries(candle_opening_times, true);

        Print("The starting hour for the session drawing is ----->", getSessionStartTime(start_bar_time_));
        Print("The ending hour for the session drawing is ----->", getSessionEndTime(start_bar_time_));
        Print("The days back is ----->", inp_days_back);

        session_drawer_.drawSession(session_.session, start_bar_time_, end_bar_time_);
    }
    void onCalculate(int rates_total, int prev_calculated, const datetime &time[])
    {

        int candles_to_skip = (session_.session_hour_duration * SECONDS_IN_AN_HOUR) / PeriodSeconds(_Period);

        // Print("The session duration is --->", session_.session_hour_duration, " and the candle to skip are -->", candles_to_skip);

        // Check the next drawing time and if it has reached then draw the session
        // Print("The latest bar is ---->", time[0]);
        // Print("An earlier bar is ---->", time[100]);
        // for (int i = prev_calculated; i < rates_total; i++) {
        //     datetime candle_opening_time = time[i];
        //     datetime time_in_utc = time_converter.getBrokerTimeInUTC(candle_opening_time);
        //     Print("The utc time of the current candle is: ", time_in_utc);
        //     Print("The server time of the current candle is: ", candle_opening_time);
        //     i += candles_to_skip;
        // }
    }
    void onDeinit()
    {}

  private:
    datetime getSessionStartTime(datetime day)
    {
        MqlDateTime start_time = {};
        TimeToStruct(day, start_time);

        start_time.hour = session_.open_hour;
        start_time.min = session_.open_minute;
        start_time.sec = 0;

        if (session_time_converter_.isDSTActive(broker_time_converter_.getBrokerTimeInUTC(day), session_.dst_rule)) {
            start_time.hour = session_.open_hour - 1;
        }

        return StructToTime(start_time);
    }

    datetime getSessionEndTime(datetime day)
    {
        datetime previous_day = day - SECONDS_IN_A_DAY;
        datetime session_previous_day_start_time = getSessionEndTime(previous_day);

        return session_previous_day_start_time + (session_.session_hour_duration * SECONDS_IN_AN_HOUR);
    }
};

//--- Global variables
SessionManager session_manager_sydney(SYDNEY_SESSION_INFO, inp_show_sydney);
// SessionManager session_manager_tokyo(TOKYO_SESSION_INFO, inp_show_tokyo);
// SessionManager session_manager_newyork(NEWYORK_SESSION_INFO, inp_show_newyork);

//+------------------------------------------------------------------+
//| Expert initialization function
//+------------------------------------------------------------------+
int OnInit()
{
    // Code here
    session_manager_sydney.onInit();
    // session_manager_tokyo.onInit();
    // session_manager_newyork.onInit();

    ChartRedraw(CURRENT_CHART);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    session_manager_sydney.onDeinit();
    // session_manager_tokyo.onDeinit();
    // session_manager_newyork.onDeinit();
}

//+------------------------------------------------------------------+
//| Expert tick function |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
    session_manager_sydney.onCalculate(rates_total, prev_calculated, time);
    // session_manager_tokyo.onCalculate(rates_total, prev_calculated, time);
    // session_manager_newyork.onCalculate(rates_total, prev_calculated, time);
    return rates_total;
}
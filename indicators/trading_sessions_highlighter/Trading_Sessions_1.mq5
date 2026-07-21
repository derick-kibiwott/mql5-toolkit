//+------------------------------------------------------------------+
//|                                           SessionHighlighter.mq5 |
//|                                      Copyright 2026, Derek Kibel |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Derek Kibel"
#property link ""
#property version "1.10"
#property indicator_chart_window

//--- Input Parameters
enum ENUM_BROKER_DST
{
    DST_US,
    DST_EUR,
    DST_NONE
};

input group "Broker Timezone Settings" input int Broker_Winter_GMT = 2; // Broker Winter GMT Offset (e.g., 2 for EET)
input ENUM_BROKER_DST Broker_DST = DST_US;                              // Broker DST Rule (US covers NY Close)

input group "Sydney Session" input bool Enable_Sydney = true; // Enable Sydney Session
input color Sydney_Color = clrLightPink;                      // Sydney Box Color
input int Sydney_Duration = 9;                                // Duration in hours

input group "Tokyo Session" input bool Enable_Tokyo = true; // Enable Tokyo Session
input color Tokyo_Color = clrLightCoral;                    // Tokyo Box Color
input int Tokyo_Duration = 9;                               // Duration in hours

input group "London Session" input bool Enable_London = true; // Enable London Session
input color London_Color = clrLightGreen;                     // London Box Color
input int London_Duration = 9;                                // Duration in hours

input group "New York Session" input bool Enable_NY = true; // Enable New York Session
input color NY_Color = clrLightSkyBlue;                     // New York Box Color
input int NY_Duration = 9;                                  // Duration in hours

input group "Drawing Settings" input int Max_Days_Back = 20; // Number of historical days to shade

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up both the shaded boxes and the text labels
    ObjectsDeleteAll(0, "SessionBox_");
    ObjectsDeleteAll(0, "SessionText_");
}

//+------------------------------------------------------------------+
//| DST Logic Checkers                                               |
//+------------------------------------------------------------------+
bool IsUSDST(datetime gmtTime)
{
    datetime local = gmtTime - 5 * 3600; // EST (GMT-5)
    MqlDateTime tm;
    TimeToStruct(local, tm);

    if (tm.mon > 3 && tm.mon < 11)
        return true;
    if (tm.mon < 3 || tm.mon > 11)
        return false;

    MqlDateTime firstDay = tm;
    firstDay.day = 1;
    TimeToStruct(StructToTime(firstDay), firstDay);

    if (tm.mon == 3)
    {
        int secondSunday = 1 + (7 - firstDay.day_of_week) % 7 + 7;
        if (tm.day > secondSunday)
            return true;
        if (tm.day == secondSunday && tm.hour >= 2)
            return true;
        return false;
    }
    if (tm.mon == 11)
    {
        int firstSunday = 1 + (7 - firstDay.day_of_week) % 7;
        if (tm.day < firstSunday)
            return true;
        if (tm.day == firstSunday && tm.hour < 2)
            return true;
        return false;
    }
    return false;
}

bool IsEuropeDST(datetime gmtTime)
{
    datetime local = gmtTime; // Europe base is GMT
    MqlDateTime tm;
    TimeToStruct(local, tm);

    if (tm.mon > 3 && tm.mon < 10)
        return true;
    if (tm.mon < 3 || tm.mon > 10)
        return false;

    MqlDateTime firstDay = tm;
    firstDay.day = 1;
    TimeToStruct(StructToTime(firstDay), firstDay);
    int lastSunday = 31 - ((firstDay.day_of_week + 30) % 7);

    if (tm.mon == 3)
    {
        if (tm.day > lastSunday)
            return true;
        if (tm.day == lastSunday && tm.hour >= 1)
            return true;
        return false;
    }
    if (tm.mon == 10)
    {
        if (tm.day < lastSunday)
            return true;
        if (tm.day == lastSunday && tm.hour < 1)
            return true;
        return false;
    }
    return false;
}

bool IsAUDST(datetime gmtTime)
{
    datetime local = gmtTime + 10 * 3600; // AEST (GMT+10)
    MqlDateTime tm;
    TimeToStruct(local, tm);

    if (tm.mon > 10 || tm.mon < 4)
        return true;
    if (tm.mon > 4 && tm.mon < 10)
        return false;

    MqlDateTime firstDay = tm;
    firstDay.day = 1;
    TimeToStruct(StructToTime(firstDay), firstDay);
    int firstSunday = 1 + (7 - firstDay.day_of_week) % 7;

    if (tm.mon == 10)
    {
        if (tm.day > firstSunday)
            return true;
        if (tm.day == firstSunday && tm.hour >= 2)
            return true;
        return false;
    }
    if (tm.mon == 4)
    {
        if (tm.day < firstSunday)
            return true;
        if (tm.day == firstSunday && tm.hour < 2)
            return true;
        return false;
    }
    return false;
}

int GetBrokerOffset(datetime serverTime)
{
    int baseOffset = Broker_Winter_GMT;
    datetime assumedGMT = serverTime - baseOffset * 3600;

    if (Broker_DST == DST_US && IsUSDST(assumedGMT))
        return baseOffset + 1;
    if (Broker_DST == DST_EUR && IsEuropeDST(assumedGMT))
        return baseOffset + 1;

    return baseOffset;
}

//+------------------------------------------------------------------+
//| Core Time & Box Logic                                            |
//+------------------------------------------------------------------+
void GetSessionTimes(datetime tradingDayMidnight, string session, datetime &outStart, datetime &outEnd, int duration)
{
    int offset = GetBrokerOffset(tradingDayMidnight);
    datetime gmtMidnight = tradingDayMidnight - offset * 3600;
    int startHourGMT = 0;

    if (session == "Sydney")
    {
        startHourGMT = IsAUDST(gmtMidnight) ? 21 : 22;
        outStart = gmtMidnight - 24 * 3600 + startHourGMT * 3600;
    }
    else if (session == "Tokyo")
    {
        startHourGMT = 0;
        outStart = gmtMidnight + startHourGMT * 3600;
    }
    else if (session == "London")
    {
        startHourGMT = IsEuropeDST(gmtMidnight) ? 7 : 8;
        outStart = gmtMidnight + startHourGMT * 3600;
    }
    else if (session == "NY")
    {
        startHourGMT = IsUSDST(gmtMidnight) ? 12 : 13;
        outStart = gmtMidnight + startHourGMT * 3600;
    }

    outEnd = outStart + duration * 3600;

    // Map back to server time using the exact offset at the session moment
    outStart = outStart + GetBrokerOffset(outStart) * 3600;
    outEnd = outEnd + GetBrokerOffset(outEnd) * 3600;
}

bool GetHighLow(datetime startTime, datetime endTime, double &outHigh, double &outLow)
{
    double high[], low[];
    int copiedH = CopyHigh(Symbol(), Period(), startTime, endTime, high);
    int copiedL = CopyLow(Symbol(), Period(), startTime, endTime, low);

    if (copiedH > 0 && copiedL > 0)
    {
        outHigh = high[ArrayMaximum(high)];
        outLow = low[ArrayMinimum(low)];
        return true;
    }
    return false;
}

void DrawSession(string sessionName, datetime dayMidnight, color clr, int durationHours)
{
    datetime startTime, endTime;
    GetSessionTimes(dayMidnight, sessionName, startTime, endTime, durationHours);

    datetime currentTime = TimeCurrent();
    if (startTime > currentTime)
        return; // Ignore future sessions

    bool isPast = (endTime <= currentTime);
    string objName = "SessionBox_" + sessionName + "_" + TimeToString(dayMidnight, TIME_DATE);
    string textObjName = "SessionText_" + sessionName + "_" + TimeToString(dayMidnight, TIME_DATE);

    if (ObjectFind(0, objName) >= 0)
    {
        if (isPast)
            return; // Do not recalculate finalized historical boxes/text
    }

    double highPrice, lowPrice;
    if (!GetHighLow(startTime, endTime, highPrice, lowPrice))
        return;

    // --- DRAW BOX ---
    if (ObjectFind(0, objName) < 0)
    {
        ObjectCreate(0, objName, OBJ_RECTANGLE, 0, startTime, highPrice, endTime, lowPrice);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, objName, OBJPROP_BACK, true); // Draws behind candles
        ObjectSetInteger(0, objName, OBJPROP_FILL, true);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
        ObjectSetString(0, objName, OBJPROP_TOOLTIP, sessionName + " Session");
    }
    else
    {
        ObjectSetInteger(0, objName, OBJPROP_TIME, 0, startTime);
        ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, highPrice);
        ObjectSetInteger(0, objName, OBJPROP_TIME, 1, endTime);
        ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, lowPrice);
    }

    // --- DRAW TEXT LABEL ---
    if (ObjectFind(0, textObjName) < 0)
    {
        ObjectCreate(0, textObjName, OBJ_TEXT, 0, startTime, highPrice);
        ObjectSetString(0, textObjName, OBJPROP_TEXT, "  " + sessionName); // Added spacing pad
        ObjectSetInteger(0, textObjName, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, textObjName, OBJPROP_FONTSIZE, 9);
        ObjectSetString(0, textObjName, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, textObjName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER); // Anchors text ABOVE the box
        ObjectSetInteger(0, textObjName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, textObjName, OBJPROP_HIDDEN, true);
    }
    else
    {
        // Update text position on active bars
        ObjectSetInteger(0, textObjName, OBJPROP_TIME, 0, startTime);
        ObjectSetDouble(0, textObjName, OBJPROP_PRICE, 0, highPrice);
    }
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[])
{
    if (rates_total < 100)
        return 0; // Ensure basic history exists

    datetime currentServerTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentServerTime, dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    datetime currentMidnight = StructToTime(dt);

    for (int i = 0; i < Max_Days_Back; i++)
    {
        datetime loopMidnight = currentMidnight - i * 24 * 3600;

        TimeToStruct(loopMidnight, dt);
        // Exclude drawing starting strictly on the weekend gap
        if (dt.day_of_week == 0 || dt.day_of_week == 6)
            continue;

        if (Enable_Sydney)
            DrawSession("Sydney", loopMidnight, Sydney_Color, Sydney_Duration);
        if (Enable_Tokyo)
            DrawSession("Tokyo", loopMidnight, Tokyo_Color, Tokyo_Duration);
        if (Enable_London)
            DrawSession("London", loopMidnight, London_Color, London_Duration);
        if (Enable_NY)
            DrawSession("NY", loopMidnight, NY_Color, NY_Duration);
    }

    return rates_total;
}
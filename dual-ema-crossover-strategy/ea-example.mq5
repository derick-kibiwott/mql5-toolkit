//+------------------------------------------------------------------+
//|                                                           EA.mq5 |
//|                                  Copyright 2026, Derick Kibiwott |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Derick Kibiwott"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Include the standard MQL5 Trade library for robust order execution
#include <Trade\Trade.mqh>

//--- Input Parameters
input group "--- Strategy Settings ---"
input int            InpFastEMAPeriod  = 9;          // Fast EMA Period
input int            InpSlowEMAPeriod  = 21;         // Slow EMA Period

input group "--- Risk Management ---"
input double         InpLotSize        = 0.1;        // Trade Volume (Lots)
input int            InpStopLoss       = 1500;       // Stop Loss (Points - e.g., 150 points for Gold)
input int            InpTakeProfit     = 3000;       // Take Profit (Points - e.g., 300 points for Gold)
input ulong          InpMagicNumber    = 888111;     // Expert Magic Number

//--- Global Variables
CTrade      trade;          // Trade execution object
int         fastEMAHandle;  // Handle for the fast EMA indicator
int         slowEMAHandle;  // Handle for the slow EMA indicator
datetime    lastBarTime;    // Tracks the timestamp of the current bar

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   // Assign the magic number to our trade object to track its own positions exclusively
   trade.SetExpertMagicNumber(InpMagicNumber);
   
   // Initialize the indicator handles
   fastEMAHandle = iMA(_Symbol, _Period, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   slowEMAHandle = iMA(_Symbol, _Period, InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   
   // Validate that handles were correctly initialized by the terminal
   if(fastEMAHandle == INVALID_HANDLE || slowEMAHandle == INVALID_HANDLE) {
      Print("❌ Failed to create indicator handles. Initialization aborted.");
      return(INIT_FAILED);
   }

   Print("🚀 EA initialized successfully.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Release handles from memory to remain efficient
   IndicatorRelease(fastEMAHandle);
   IndicatorRelease(slowEMAHandle);
   Print("⚠️ EA deinitialized.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   // 1. Bar Filter: Only run calculations when a new candle opens
   if(!IsNewBar()) return;

   // 2. Prepare dynamic arrays to store the indicator data
   double fastEMA[], slowEMA[];
   
   // Set array indexing to match chart direction (index 1 = last closed bar)
   ArraySetAsSeries(fastEMA, true);
   ArraySetAsSeries(slowEMA, true);
   
   // Copy recent values from the indicators into local arrays
   if(CopyBuffer(fastEMAHandle, 0, 0, 3, fastEMA) < 3 ||
      CopyBuffer(slowEMAHandle, 0, 0, 3, slowEMA) < 3) {
      Print("⚠️ Failed to copy indicator data. Waiting for next bar.");
      return;
   }

   // 3. Logic: Analyze completely closed data to avoid repainting issues
   // Buy Signal: Fast EMA was below or equal to slow EMA 2 bars ago, but crossed ABOVE 1 bar ago.
   bool buySignal  = (fastEMA[1] > slowEMA[1]) && (fastEMA[2] <= slowEMA[2]);
   
   // Sell Signal: Fast EMA was above or equal to slow EMA 2 bars ago, but crossed BELOW 1 bar ago.
   bool sellSignal = (fastEMA[1] < slowEMA[1]) && (fastEMA[2] >= slowEMA[2]);

   // 4. Position Guard: Check if this specific EA already has an open position
   bool hasPosition = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) {
         hasPosition = true;
         break;
      }
   }

   // 5. Execution Pipeline
   if(!hasPosition) {
      if(buySignal) {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double sl  = ask - (InpStopLoss * _Point);
         double tp  = ask + (InpTakeProfit * _Point);
         
         trade.Buy(InpLotSize, _Symbol, ask, sl, tp, "EMA Cross Buy");
         Print("📊 Buy Order Sent.");
      }
      else if(sellSignal) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double sl  = bid + (InpStopLoss * _Point);
         double tp  = bid - (InpTakeProfit * _Point);
         
         trade.Sell(InpLotSize, _Symbol, bid, sl, tp, "EMA Cross Sell");
         Print("📊 Sell Order Sent.");
      }
   }
}

//+------------------------------------------------------------------+
//| Helper function to detect candle structural changes               |
//+------------------------------------------------------------------+
bool IsNewBar() {
   datetime currentBarTime = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(currentBarTime != lastBarTime) {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}
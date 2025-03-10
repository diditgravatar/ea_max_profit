//+------------------------------------------------------------------+
//| EA XAUUSD Optimal Profit                                        |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;

// === INPUT PARAMETER ===
input double RiskPercent = 2.0;
input int ADX_Period = 14;
input double ADX_Threshold = 25;
input int RSI_Period = 14;
input int RSI_Buy_Level = 70;
input int RSI_Sell_Level = 30;
input int MA_Short = 35;
input int MA_Long = 82;
input int ATR_Period = 14;
input int TrailingStopPips = 50;
input int BreakEvenPips = 30;
input double MaxDrawdown = 10;
input int StartHour = 8, EndHour = 23;  // Jam Trading Optimal (GMT)

//+------------------------------------------------------------------+
//| Fungsi Mengecek Jam Trading Optimal                             |
//+------------------------------------------------------------------+
bool IsTradingTime() {
   datetime timeNow = TimeCurrent();
   int hourNow = TimeHour(timeNow);
   return (hourNow >= StartHour && hourNow <= EndHour);
}

//+------------------------------------------------------------------+
//| Fungsi Break-even Stop Loss                                      |
//+------------------------------------------------------------------+
void ApplyBreakEven() {
   for (int i = 0; i < PositionsTotal(); i++) {
      if (PositionSelect(i)) {
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double sl = PositionGetDouble(POSITION_SL);
         double profitPips = (currentPrice - openPrice) / _Point;

         if (profitPips >= BreakEvenPips && sl == 0) {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
               trade.PositionModify(PositionGetInteger(POSITION_TICKET), openPrice, PositionGetDouble(POSITION_TP));
            } else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
               trade.PositionModify(PositionGetInteger(POSITION_TICKET), openPrice, PositionGetDouble(POSITION_TP));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Fungsi Trailing Stop                                             |
//+------------------------------------------------------------------+
void ApplyTrailingStop() {
   for (int i = 0; i < PositionsTotal(); i++) {
      if (PositionSelect(i)) {
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double sl = PositionGetDouble(POSITION_SL);
         double newSL;

         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            newSL = currentPrice - (TrailingStopPips * _Point);
            if (newSL > sl) trade.PositionModify(PositionGetInteger(POSITION_TICKET), newSL, PositionGetDouble(POSITION_TP));
         } 
         else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            newSL = currentPrice + (TrailingStopPips * _Point);
            if (newSL < sl) trade.PositionModify(PositionGetInteger(POSITION_TICKET), newSL, PositionGetDouble(POSITION_TP));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Fungsi utama EA                                                 |
//+------------------------------------------------------------------+
void OnTick() {
   if (!IsTradingTime()) return;  // Hanya trading di jam optimal

   ApplyBreakEven();
   ApplyTrailingStop();

   if (PositionsTotal() == 0) {
      OpenTrade();
   }
}

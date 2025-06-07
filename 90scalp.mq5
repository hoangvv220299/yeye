#property copyright "Copyright 2024, HoangVuViet1999"
#property link      "https://www.mql5.com"
#property version   "4.00"

//=== LIBRARY ========================================
#include <Trade/Trade.mqh>
#include <Controls/Label.mqh>

//=== ENUM / STRUCT / CLASS / OBJECT =====================================
enum ENUM_TIME_HOURS{
   _INACTIVE = 0, _0100, _0200, _0300, _0400, _0500, _0600, _0700, _0800, _0900, _1000, _1100, _1200,
   _1300, _1400, _1500, _1600, _1700, _1800, _1900, _2000, _2100, _2200, _2300   
};


enum ENUM_TIME_MINS{
   _00, _01, _02, _03, _04, _05, _06, _07, _08, _09,
   _10, _11, _12, _13, _14, _15, _16, _17, _18, _19,
   _20, _21, _22, _23, _24, _25, _26, _27, _28, _29,
   _30, _31, _32, _33, _34, _35, _36, _37, _38, _39,
   _40, _41, _42, _43, _44, _45, _46, _47, _48, _49,
   _50, _51, _52, _53, _54, _55, _56, _57, _58, _59  
};

enum ENUM_SYSTEM_TYPE{
   _FOREX = 0, _BITCOIN, _GOLD, _INDICIES
};

enum  ENUM_SEP_DROPDOWN{
   _COMMA = 0, _SEMICOLON
};

enum ENUM_NEWS_LV{
   _LOW = 0,
   _MEDIUM = 1,
   _HIGH = 2
};


//=== INPUT ============================================================
input group "=== Profiles ==="
input ENUM_SYSTEM_TYPE  systemType        = _FOREX;   //Trading system applied (Forex, Crypto, Gold, Indices) [_FOREX]

input group "=== Common Inputs ==="
input ENUM_TIMEFRAMES   mainTf            = PERIOD_M5;//Timeframe [M5]
input double            riskPercents      = 2;        //Risk in % per Trade (%) [3.0]

input group "=== Logic Strategy ===" 
input int               fractalNumberFx   = 5;        //Bars Number to identify high/low Fractals [5]
input int               maxBarsFx         = 200;      //Max Bars to find Fractals [200]
input int               expirationBarsFx  = 100;      //Bars Number to hold pending Order before expire [100]

input group "=== ATR for SL/TP === "
input ENUM_TIMEFRAMES   atrTf             = PERIOD_M5;//ATR Timeframe
input int               atrPeriod         = 14;       //ATR Period


//+---------------------------------------------------------------+
//| Pair    | Spread    | Slippage  | Stoploss  | Pullback        |
//+---------+-----------+-----------+-----------+-----------------+
//| GBPUSD  | 5 pts     | 1 pts     | 3 ATR     | 110 points 0.85 |
//| EURUSD  | 3 pts     | 1 pts     | 3 ATR     | 110 points 0.95 |
//| USDJPY  | 5 pts     | 1 pts     | 3 ATR     | 140 points 0.95 |
//| Bitcoin | 5% * 0.4  | 100 pts   | 2 ATR     | 0.4/2 price [df]|
//| Gold    | 18 pts    |           | 2 ATR     | 0.2/2 price [df]|
//+---------------------------------------------------------------+
//+---------------------------------------------+
//| Pair    | Trigger   | Trailing  | Spread    |
//+---------+-----------+-----------+-----------+
//| GBPUSD  | 15 pts    | 10 pts    | 5 pts     |
//| EURUSD  | 15 pts    | 10 pts    | 3 pts     |
//| USDJPY  | 15 pts    | 10 pts    | 5 pts     |     
//| Bitcoin | 8% * 0.4  | 6% * 0.4  | 5% * 0.4  | 
//| Gold    | 6% * 0.2  | 4% * 0.2  | 18 pts    |
//+---------------------------------------------+
//+------------------------------------------------------------+
//| Pair    | Day          | London | Newyork| BeforS | BeforE | 
//+---------+--------------+--------+--------+--------+--------+
//| GBPUSD  | Tues - Fri   | 08-12h | 15-19h | 15 min | 30 min |
//| EURUSD  | Tues - Fri   | 08-12h | 15-19h | 15 min | 30 min |
//| USDJPY  | Tues - Fri   | 08-12h | 15-19h | 15 min | 30 min |    
//| Bitcoin | Sun - Fri    | 08-12h | 12-04h | 15 min | 30 min |
//| Gold    | Weds - Fri   | 10-12h | 13-19h | 15 min | 30 min |
//+------------------------------------------------------------+

input group "===== Forex Inputs ===== (Forex)"
input double   slAtrFactorFx        = 3;        //ATR Factor for SL [3]
input double   tpAtrFactorFx        = 3;        //ATR Factor for TP [3]
input int      tslTriggerPointsFx   = 15;       //Trigger points in profit before Trailing SL [15]
input int      tslPointsFx          = 10;       //Trailing Stop Points [10]
//input int      pullbackPointsFx     = 110;      //Min Points from pullback to Entry [110]
input double   pullbackFactorGU     = 0.85;     //Pullback distance Factor GBPUSD
input int      maxSpreadPointsGU    = 5;        //Max Spread points GBPUSD
input double   pullbackFactorEU     = 0.95;     //Pullback distance Factor EURUSD
input int      maxSpreadPointsEU    = 3;        //Max Spread points EURUSD
input double   pullbackFactorUJ     = 0.95;     //Pullback distance Factor USDJPY
input int      maxSpreadPointsUJ    = 5;        //Max Spread points USDJPY
input int      maxSlippagePointsFx  = 1;        //Max Slippage points 

input group "=== Forex Trading times === (Forex)"
input ENUM_TIME_HOURS   sLdInp      = _0800;       //London session Start Hour     
input ENUM_TIME_HOURS   eLdInp      = _1200;       //London session End Hour 
input ENUM_TIME_HOURS   sNyInp      = _1500;       //Newyork sesssion Start Hour    
input ENUM_TIME_HOURS   eNyInp      = _1900;       //Newyork session End Hour 
input ENUM_TIME_MINS    bfSMinInp   = _15;         //Min before Start Hour
input ENUM_TIME_MINS    bfEMinInp   = _30;         //Min before End Hour
input bool              excTime1Inp = false;       //Except time 1?
input ENUM_TIME_HOURS   exc1SInp    = _0900;       //Except time 1 Start Hour      
input ENUM_TIME_HOURS   exc1EInp    = _1000;       //Except time 1 End Hour 
input bool              excTime2Inp = false;       //Except time 2?
input ENUM_TIME_HOURS   exc2SInp    = _1500;       //Except time 2 Start Hour 
input ENUM_TIME_HOURS   exc2EInp    = _1600;       //Except time 2 End Hour 
input ENUM_DAY_OF_WEEK  sDayInp     = TUESDAY;     //Weekday Start (SUNDAY=0)     
input ENUM_DAY_OF_WEEK  eDayInp     = FRIDAY;      //Weekday End (SATURDAY=6) 


input group "===== Crypto Inputs ===== (Bitcoin)"
input double   slAtrFactorBit             = 2;        //ATR Factor for SL [2]
input double   tpAtrFactorBit             = 2;        //ATR Factor for TP [2]
input double   tpAsPct                    = 0.4;      //TP as % of Price for TSL & Pullpack [0.4]
input double   tslAsPctOfTp               = 6;        //Trail SL as % of TP [5.0]
input double   tslTriggerPctOfTp          = 8;        //Trigger of trail SL % of TP [7.0]
input double   maxSpreadPctOfTpBit        = 5;      //Max Spread as % of TP
input int      maxSlippagePointsBit       = 100;      //Max Slippage points 

input group "=== Crypto Trading times === (Bitcoin)"
input ENUM_TIME_HOURS   sLdInpBit         = _0200;       //London session Start Hour      
input ENUM_TIME_HOURS   eLdInpBit         = _1200;       //London session End Hour 
input ENUM_TIME_HOURS   sNyInpBit         = _1200;       //Newyork sesssion Start Hour    
input ENUM_TIME_HOURS   eNyInpBit         = _2100;       //Newyork session End Hour 
input ENUM_TIME_MINS    bfSMinInpBit      = _15;         //Min before Start Hour
input ENUM_TIME_MINS    bfEMinInpBit      = _30;         //Min before End Hour
input bool              excTime1InpBit    = false;       //Except time 1?
input ENUM_TIME_HOURS   exc1SInpBit       = _0900;       //Except time 1 Start Hour      
input ENUM_TIME_HOURS   exc1EInpBit       = _1000;       //Except time 1 End Hour 
input bool              excTime2InpBit    = false;       //Except time 2?
input ENUM_TIME_HOURS   exc2SInpBit       = _2200;       //Except time 2 Start Hour 
input ENUM_TIME_HOURS   exc2EInpBit       = _0100;       //Except time 2 End Hour 
input ENUM_DAY_OF_WEEK  sDayInpBit        = MONDAY;      //Weekday Start (SUNDAY=0)     
input ENUM_DAY_OF_WEEK  eDayInpBit        = FRIDAY;      //Weekday End (SATURDAY=6) 

input group "===== Gold Inputs ===== (Gold)"
input double   slAtrFactorGold            = 2;           //ATR Factor for SL
input double   tpAtrFactorGold            = 2;           //ATR Factor for TP
input double   tpAsPctGold                = 0.2;         //TP as % of Price for TSL & Pullpack 
input double   tslAsPctOfTpGold           = 4;           //Trail SL as % of TP 
input double   tslTriggerPctOfTpGold      = 6;           //Trigger of trail SL % of TP 
//input double   maxSpreadPctOfTpGold       = 2;           //Max Spread as % of TP
input int      maxSpreadPointsGold        = 18;          //Max Spread points
input int      maxSlippagePointsGold      = 1;           //Max Slippage points

input group "=== Gold Trading times === (Gold)"
input ENUM_TIME_HOURS   sLdInpGold        = _1000;       //London session Start Hour [8h]     
input ENUM_TIME_HOURS   eLdInpGold        = _1200;       //London session End Hour [12h]
input ENUM_TIME_HOURS   sNyInpGold        = _1300;       //Newyork sesssion Start Hour [15h]    
input ENUM_TIME_HOURS   eNyInpGold        = _1900;       //Newyork session End Hour [19h]
input ENUM_TIME_MINS    bfSMinInpGold     = _15;         //Min before Start Hour
input ENUM_TIME_MINS    bfEMinInpGold     = _30;         //Min before End Hour
input bool              excTime1InpGold   = false;       //Except time 1?
input ENUM_TIME_HOURS   exc1SInpGold      = _0900;       //Except time 1 Start Hour      
input ENUM_TIME_HOURS   exc1EInpGold      = _1000;       //Except time 1 End Hour 
input bool              excTime2InpGold   = false;       //Except time 2?
input ENUM_TIME_HOURS   exc2SInpGold      = _1500;       //Except time 2 Start Hour 
input ENUM_TIME_HOURS   exc2EInpGold      = _1600;       //Except time 2 End Hour 
input ENUM_DAY_OF_WEEK  sDayInpGold       = WEDNESDAY;   //Weekday Start (SUNDAY=0)   
input ENUM_DAY_OF_WEEK  eDayInpGold       = FRIDAY;      //Weekday End (SATURDAY=6) 


input group "===== Indices Inputs ===== (Indicies)"
input double   slAtrFactorIndicies           = 2;           //ATR Factor for SL
input double   tpAtrFactorIndicies           = 2;           //ATR Factor for TP
input double   tpAsPctIndicies               = 0.2;         //TP as % of Price for TSL & Pullpack [0.2]
input double   tslAsPctOfTpIndicies          = 5;           //Trail SL as % of TP [5.0]
input double   tslTriggerPctOfTpIndicies     = 7;           //Trigger of trail SL % of TP [7.0]
//input double   maxSpreadPctOfTpIndicies      = 4;           //Max Spread as % of TP
input int      maxSpreadPointsIndices        = 12;          //Max Spread points
input int      maxSlippagePointsIndicies     = 20;          //Max Slippage points [None]

input group "=== Indicies Trading times === (Indicies)"
input ENUM_TIME_HOURS   sLdInpIndicies       = _0800;       //London session Start Hour [8h]     
input ENUM_TIME_HOURS   eLdInpIndicies       = _1200;       //London session End Hour [12h]
input ENUM_TIME_HOURS   sNyInpIndicies       = _1500;       //Newyork sesssion Start Hour [15h]    
input ENUM_TIME_HOURS   eNyInpIndicies       = _1900;       //Newyork session End Hour [19h]
input ENUM_TIME_MINS    bfSMinInpIndicies    = _15;         //Min before Start Hour
input ENUM_TIME_MINS    bfEMinInpIndicies    = _30;         //Min before End Hour
input bool              excTime1InpIndicies  = false;       //Except time 1?
input ENUM_TIME_HOURS   exc1SInpIndicies     = _0900;       //Except time 1 Start Hour      
input ENUM_TIME_HOURS   exc1EInpIndicies     = _1000;       //Except time 1 End Hour 
input bool              excTime2InpIndicies  = false;       //Except time 2?
input ENUM_TIME_HOURS   exc2SInpIndicies     = _1500;       //Except time 2 Start Hour 
input ENUM_TIME_HOURS   exc2EInpIndicies     = _1600;       //Except time 2 End Hour 
input ENUM_DAY_OF_WEEK  sDayInpIndicies      = TUESDAY;     //Weekday Start (SUNDAY=0) [MONDAY]     
input ENUM_DAY_OF_WEEK  eDayInpIndicies      = FRIDAY;      //Weekday End (SATURDAY=6) [FRIDAY]


input group "=== Chart Tetting ==="
input color    chartColorTradingOff    = clrPink;     //Chart color when EA Inactive
input color    chartColorTradingOn     = clrBlack;    //Chart color when EA Active
input bool     hideIndicators          = true;        //Hide Indicators on chart?

input group "=== News Fillter ==="
input bool     newsFilterOn            = false;        //Filter by Important Keywords?
input string   keyNews                 = "FOMC,Non-Farm,NFP,Interest Rate,OPEC,PCE,Dot Plot"; //Important Keywords in News to avoid (separated by separator)
input bool     newsFilterByLv          = false;        //Filter by Optional Keywords with Important LV?
input string   optionalKeyNews         = "CPI,GDP,PPI,Unemployment Rate,Employment Change,Retail, Sales,PMI,Confidence,Housing,FED,ECB,BOJ,BOE"; //Optional Keywords       
input ENUM_NEWS_LV filterLv            = _MEDIUM;     //Important Level 
input ENUM_SEP_DROPDOWN separator      = _COMMA;      //Separator to separate news keywords

input string   newsCurrenciesInp       = "USD,GBP,EUR,JPY"; //Currencies for News LookUp
input int      daysNewsLookUp          = 2;           //Days Number to look up news
input int      stopBeforeMin           = 15;          //Stop trading before (minutes)
input int      startAfterMin           = 15;          //Start trading after (minutes) 

input group "=== RSI Filter ==="
input bool                 rsiFilterOn = false;        //Filter by RSI extremes?
input ENUM_TIMEFRAMES      rsiTf       = PERIOD_M5;   //Timeframe for RSI
input int                  rsiOb       = 70;          //RSI Upper OB level
input int                  rsiOs       = 30;          //RSI Lower OS level
input int                  rsiPeriod   = 14;          //RSI Period
input ENUM_APPLIED_PRICE   rsiAppPrice = PRICE_MEDIAN;//RSI Applied Price

input group "===MA Filter===" 
input bool                 maFilterOn  = false;       //Filter by MA extremes?
input ENUM_TIMEFRAMES      maTf        = PERIOD_H4;   //MA Timeframe
input double               pctFromMa   = 3;           //% Price is away from MA to be extreme
input int                  maPeriod    = 200;         //MA Period
input ENUM_MA_METHOD       maMode      = MODE_EMA;    //MA Mode
input ENUM_APPLIED_PRICE   maAppPrice  = PRICE_MEDIAN;//MA Applied Price         

input group "=== ID of EA ==="
input int      magicNumber             = 7;           //ID of EA on server  
input string   commentary              = "BF SL 3ATR";//Comments of EA on server      


//=== CONST ===============================
const int      _MAIN_LINE  = 0;
const double   _POINT      = _Point;
const int      _DIGITS     = _Digits;
const string   _SYMBOL     = _Symbol; 


//=== VARIALBE =========================================
int      systemChoice;

//logic variable
int      fractalNumber;  
int      maxBars;    
int      expirationBars;  

//sl tp variable
double   slAtrFactor, tpAtrFactor;
double   tpPoints, slPoints, tslTriggerPoints, tslPoints;
double   pullbackPoints;

double   pullbackFactorFx;    
int      maxSpreadPointsFx;       

double   maxSpreadPoints;
bool     isValidSpread = true;

double   maxSlippagePoints;
double   lastBuyStopEntry, lastSellStopEntry;

//time variable        
int      startLd, endLd;
int      startNy, endNy;
int      bfSMin, bfEMin;
bool     isValidTime = true;

int      exc1S, exc1E, exc2S, exc2E;

bool     excTime1 = false, excTime2 = false; 


int      startWeekDay;
int      endWeekDay;
bool     isValidDay = true;

//indicators varible
int      handleRsi, handleMa, handleAtr, handleSma;
double   atrClosed;

CTrade   trade;
CLabel   spread_label, enabled_trading_label;

int      buyTotals;
int      sellTotals;
   
//avoided trading by news
bool     tradingEnabled       = true;
string   tradingEnabledCmt    = "";
bool     tradingDisableNews   = false; //check the reason why trading was stop
datetime lastNewsAvoided;
bool     offChat              = false;

ushort   sep_code;                     //translate "," or ";" become a code 
string   newsToAvoid[];
int      keyTotals;

string   newsToAvoid2[];
int      optionalKeyTotals;
int      importantLv;
string   newsCurrencies;



//=== FUNCTION DECLARATION ====================================
void TrailStop(const double &ask, const double &bid);
void CloseAllPendingOrders();

void UpdateSpreadSlippage(const double &spread, const double &ask);
void CheckSlippage(const double &buySlippage, const double &sellSlippage);
bool IsGoodSpread(const double &spread);
bool IsNewbar(const datetime &currentBarTime);

bool IsTradingDay(const int &today);
string GetWeekdayName(const int &day);
bool IsTradingHour(const int &nowHour, const int &nowMin);
bool IsInTimeZone(const int &startHour, const int &endHour, const int &nowHour, const int &nowMin);


bool IsUpComingNews(const datetime &now);
bool IsRsiFilter();
bool IsMaFilter(const double &ask);
bool CheckFilter(const double &ask, const datetime &now);

bool CountOrder();

double FindHigh();
double FindLow();

void UpdateSlTp(const double &ask);

void ExcuteBuy(double entry, const double &ask);
void ExcuteSell(double entry, const double &bid);

double CalcLots(const double &slPoi);


//=== START EA FUNCTION ====================================
int OnInit(){
   trade.SetExpertMagicNumber(magicNumber);
   
   //set trading hours
   if(sLdInp == 0 || eLdInp == 0 || sNyInp == 0 || eNyInp == 0){
      Print("Timezone was invalid! Please choose timezone");
      return(INIT_FAILED);
   }
   
   
   //set system profile
   if(systemType == _FOREX){
      systemChoice = 0;    
      startLd        = sLdInp;
      endLd          = eLdInp;
      startNy        = sNyInp;
      endNy          = eNyInp;      
      bfSMin         = bfSMinInp;
      bfEMin         = bfEMinInp;  
      excTime1       = excTime1Inp;
      excTime2       = excTime2Inp;  
      exc1S          = exc1SInp; 
      exc1E          = exc1EInp;
      exc2S          = exc2SInp;
      exc2E          = exc2EInp; 
      startWeekDay   = sDayInp;
      endWeekDay     = eDayInp;
      
   }else if(systemType == _BITCOIN){
      systemChoice = 1;  
      startLd        = sLdInpBit;
      endLd          = eLdInpBit;
      startNy        = sNyInpBit;
      endNy          = eNyInpBit;       
      bfSMin         = bfSMinInpBit;
      bfEMin         = bfEMinInpBit;     
      excTime1       = excTime1InpBit;
      excTime2       = excTime2InpBit;    
      exc1S          = exc1SInpBit; 
      exc1E          = exc1EInpBit;
      exc2S          = exc2SInpBit;
      exc2E          = exc2EInpBit;   
      startWeekDay   = sDayInpBit;
      endWeekDay     = eDayInpBit;
      
   }else if(systemType == _GOLD){
      systemChoice = 2;
      startLd        = sLdInpGold;
      endLd          = eLdInpGold;
      startNy        = sNyInpGold;
      endNy          = eNyInpGold;      
      bfSMin         = bfSMinInpGold;
      bfEMin         = bfEMinInpGold;  
      excTime1       = excTime1InpGold;
      excTime2       = excTime2InpGold;  
      exc1S          = exc1SInpGold; 
      exc1E          = exc1EInpGold;
      exc2S          = exc2SInpGold;
      exc2E          = exc2EInpGold; 
      startWeekDay   = sDayInpGold;
      endWeekDay     = eDayInpGold;
      
   }else{
      systemChoice = 3;
      startLd        = sLdInpIndicies;
      endLd          = eLdInpIndicies;
      startNy        = sNyInpIndicies;
      endNy          = eNyInpIndicies;      
      bfSMin         = bfSMinInpIndicies;
      bfEMin         = bfEMinInpIndicies;  
      excTime1       = excTime1InpIndicies;
      excTime2       = excTime2InpIndicies;  
      exc1S          = exc1SInpIndicies; 
      exc1E          = exc1EInpIndicies;
      exc2S          = exc2SInpIndicies;
      exc2E          = exc2EInpIndicies; 
      startWeekDay   = sDayInpIndicies;
      endWeekDay     = eDayInpIndicies;
   }
   
   //set LOGIC default values for forex system
   fractalNumber     = fractalNumberFx;  
   maxBars           = maxBarsFx;    
   expirationBars    = expirationBarsFx;
      
   if(systemChoice == _FOREX){
      if(StringFind(_SYMBOL, "EURUSD", 0) >= 0){
         maxSpreadPointsFx = maxSpreadPointsEU;
         pullbackFactorFx = pullbackFactorEU;
      }else if(StringFind(_SYMBOL, "GBPUSD", 0) >= 0){
         maxSpreadPointsFx = maxSpreadPointsGU;
         pullbackFactorFx = pullbackFactorGU;   
      }else if(StringFind(_SYMBOL, "USDJPY", 0) >= 0){
         maxSpreadPointsFx = maxSpreadPointsUJ;
         pullbackFactorFx = pullbackFactorUJ;           
      }else{
         maxSpreadPointsFx = 5;
         pullbackFactorFx = 1; 
         Print("INVALID Symbol");   
      }
   }
   //set SL TP default values for forex system
   slAtrFactor       = slAtrFactorFx; 
   tpAtrFactor       = tpAtrFactorFx;    
   tslPoints         = tslPointsFx;
   tslTriggerPoints  = tslTriggerPointsFx;
   //pullbackPoints    = pullbackPointsFx;
   

   
   //set for news filter
   sep_code = (separator == _COMMA ? ',' : ';');        
   keyTotals = StringSplit(keyNews, sep_code, newsToAvoid);
   optionalKeyTotals = StringSplit(optionalKeyNews, sep_code, newsToAvoid2);
   newsCurrencies = newsCurrenciesInp;
   StringToLower(newsCurrencies);
   importantLv = filterLv == _LOW ? 0 : filterLv == _MEDIUM ? 1 : 2;
   
   //indicator handle
   handleRsi = iRSI(_SYMBOL, rsiTf, rsiPeriod, rsiAppPrice);
   handleMa = iMA(_SYMBOL, maTf, maPeriod, 0, maMode, maAppPrice);
   handleAtr = iATR(_SYMBOL, atrTf, atrPeriod);
   handleSma = iMA(_SYMBOL, PERIOD_D1, 14, 0, MODE_SMA, PRICE_MEDIAN);
   
   //chart setting
   spread_label.Create(0, "spread_label", 0, 5, 30, 0, 0);
   spread_label.Text("Spread: --- pts");
   spread_label.Color(clrLimeGreen);
   
   enabled_trading_label.Create(0, "enabled_trading_label", 0, 260, 2, 0, 0);
   enabled_trading_label.Text("");
   enabled_trading_label.Color(clrRed);
   
   ChartSetInteger(0, CHART_SHOW_GRID, false); 
   TesterHideIndicators(hideIndicators);
   
   Print("Added EA Successful!");  
   return(INIT_SUCCEEDED);
}


//=== END EA FUNCTION =========================================
void OnDeinit(const int reason){
   Print("Removed EA Successful!"); 
   spread_label.Destroy();  
   enabled_trading_label.Destroy();
}


//=== MAIN LOGIC ==============================================
void OnTick(){
   //----- ON EVERY TICKS -------------------------------------  
   double ask = NormalizeDouble(SymbolInfoDouble(_SYMBOL, SYMBOL_ASK), _DIGITS);
   double bid = NormalizeDouble(SymbolInfoDouble(_SYMBOL, SYMBOL_BID), _DIGITS);

   //count position + trail stop
   buyTotals = 0;
   sellTotals = 0;
   
   TrailStop(ask, bid);
   
   //count order + get last buy/sell stop entry
   lastBuyStopEntry = 0;
   lastSellStopEntry = 0;
   
   if(!CountOrder()) return;
   
   //check slippage & spread  
   int spread = (int)((ask - bid) / _POINT + 0.5); 
   UpdateSpreadSlippage(spread, ask);
    
   int buySlippage = (int)((bid - lastBuyStopEntry) / _POINT + 0.5);
   int sellSlippage = (int)((lastSellStopEntry - ask) /  _POINT + 0.5);
   CheckSlippage(buySlippage, sellSlippage);
   
   
   spread_label.Text("Spread: " + IntegerToString(spread) + " pts");
   if(!IsGoodSpread(spread)) return;    
   
   //check new bar - bar is closed?
   datetime currentBarTime = iTime(_SYMBOL, mainTf, 0);
   if(!IsNewbar(currentBarTime)) return; 
   
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, chartColorTradingOn);  
   enabled_trading_label.Text("Enable Traiding");
   enabled_trading_label.Color(clrLimeGreen);              

   //----- ONLY ON NEW BAR -------------------------------------
   //check time
   MqlDateTime time;
   datetime now = TimeCurrent();
   TimeToStruct(now, time);
   
   if(!IsTradingDay(time.day_of_week)) return;
   if(!IsTradingHour(time.hour, time.min)) return;
     
   Print("New bar: ", StringFormat("%02d:%02d", time.hour, time.min));   //new bar logs
      
   //continue trading

   
   if(tradingEnabledCmt != ""){
      Print("Enabled trading again");
      tradingEnabledCmt = "";
   }     
     
   //check filter
   if(CheckFilter(ask, now)){
      return;
   }
   
   tradingEnabled = true;
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, chartColorTradingOn);  
   offChat = false;
   enabled_trading_label.Text("Enable Traiding");
   enabled_trading_label.Color(clrLimeGreen);   
   
   //----- STRATEGY LOGIC AFTER FILTER -------------------
   double atr[];
   if(!CopyBuffer(handleAtr, _MAIN_LINE, 1, 1, atr)){
      Print("Failed to read ATR handle");
   }else atrClosed = atr[0];   
     
   //order buy/sell
   if(buyTotals <= 0){
      double high = FindHigh();
      if(high > 0){
         UpdateSlTp(ask);
         ExcuteBuy(NormalizeDouble(high, _DIGITS), ask);
      }
   }
   if(sellTotals <= 0){
      double low = FindLow();
      if(low > 0){
         UpdateSlTp(ask);
         ExcuteSell(NormalizeDouble(low, _DIGITS), bid);
      }
   }
   
}


//=== FUNCTION DEFINITION ====================================
bool IsNewbar(const datetime &currentBarTime){
   static datetime lastBarTime = 0;
   if(lastBarTime != currentBarTime){
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}


bool IsInTimeZone(const int &startHour, const int &endHour, const int &nowHour, const int &nowMin){
   
   int nowTotalMin = nowHour * 60 + nowMin;
   int startMin = ((startHour == 0 ? 24 : startHour) - 1 )* 60 + 60 - bfSMin;
   int endMin   = ((endHour   == 0 ? 24 : endHour) - 1) * 60 + 60 - bfEMin;

   if(startMin < endMin){
      return (nowTotalMin >= startMin && nowTotalMin < endMin);
   }
   else{
      return (nowTotalMin < startMin || nowTotalMin >= endMin);
   }
}

double FindHigh(){
   double highestHigh = 0;
   for(int i = 0; i < maxBars; i++){
      double high = iHigh(_SYMBOL, mainTf, i);
      if(high > highestHigh){
         highestHigh = high;
         if(i > fractalNumber && 
            iHighest(_SYMBOL, mainTf, MODE_HIGH, fractalNumber + 1, i) == i
         ) return highestHigh;
      }
   }
   return -1;
}


double FindLow(){
   double lowestLow = DBL_MAX;
   for(int i = 0; i < maxBars; i++){
      double low = iLow(_SYMBOL, mainTf, i);
      if(low < lowestLow){
         lowestLow = low;
         
         if(i > fractalNumber && 
            iLowest(_SYMBOL, mainTf, MODE_LOW, fractalNumber + 1, i) == i
         ) return lowestLow;          
      }
   }
   return -1;
}


double CalcLots(const double &slPoi){
   double riskAcc = AccountInfoDouble(ACCOUNT_BALANCE) * riskPercents / 100;
   
   double tickSize = SymbolInfoDouble(_SYMBOL, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_SYMBOL, SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(_SYMBOL, SYMBOL_VOLUME_STEP);
   
   //pointCost = tickValue / (tickSize _Point)     | value 1 lot for 1 point     
   
   //lotCost = slPoi * pointCost                   | value 1 lot for all points            
   //riskByLots = riskAcc / lotCost                | calculate by lotCost
   
   //lotStepCost = lotCost * lotStep               | 1 lot * lotStep = 1 lotStep  
   //riskByLotSteps = riskAcc / lotStepCost        | calculate by lotStepCost
   
   //double riskLots = riskAcc / slPoi * tickSize / tickValue;  // = riskAcc / (slPoi * tickValue / tickSize) 
   
   double pointCost = tickValue / (tickSize / _POINT);
   double lotCost = slPoi * pointCost;
   double lotStepCost = lotCost * lotStep;
   double riskByLotSteps = lotStep * riskAcc / lotStepCost;
   
   Print("SL Points: ", slPoi, 
      " | Tick Value($): ", tickValue, 
      " | Tick Size: ", tickSize, 
      " | Lot Step: ", lotStep, 
      " | Risk Account($): ", riskAcc
   );
   
   Print("Point Cost($): ", pointCost, 
      " | Lot Cost($): ", lotCost, 
      " | Lotstep Cost($): ", lotStepCost, 
      " | Risk lots: ", riskByLotSteps
   );
      
   int digitsVol = (int)MathLog10(1.0 / SymbolInfoDouble(_SYMBOL, SYMBOL_VOLUME_STEP));
   
   double maxVolume = SymbolInfoDouble(_SYMBOL, SYMBOL_VOLUME_MAX);   
   double minVolume = SymbolInfoDouble(_SYMBOL, SYMBOL_VOLUME_MIN);   
   
   double volumeLimit = SymbolInfoDouble(_SYMBOL, SYMBOL_VOLUME_LIMIT);
   double openedVolume = 0;
   
   if(volumeLimit != 0){      
      for (int i = 0; i < PositionsTotal(); i++){
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket)){
            if (PositionGetSymbol(i) == _SYMBOL){
               openedVolume += PositionGetDouble(POSITION_VOLUME);
            }
         }
      }
      if(riskByLotSteps > volumeLimit - openedVolume){
         Print("Volume is too large: ", riskByLotSteps, 
            " | Volume opened: ", openedVolume, 
            " | Volume Limit: ", volumeLimit
         );
         Print("Fixed volume to match with broker");    
         riskByLotSteps = volumeLimit - openedVolume;
      }
   }   
    
   if(maxVolume != 0 && riskByLotSteps > maxVolume){
      Print("Volume is too large: ", riskByLotSteps, " | Volume Max: ", maxVolume);
      Print("Fixed volume to match with broker");    
      riskByLotSteps = maxVolume;
   }
   
   if(minVolume != 0 && (riskByLotSteps < minVolume)){
      Print("Volume is too small: ", riskByLotSteps, " | Volume Min: ", minVolume, " | Lotstep: ", lotStep);
      Print("Fixed volume to match with broker");        
      riskByLotSteps = minVolume;
   }
   
   if(riskByLotSteps < lotStep){
      Print("Volume is too small: ", riskByLotSteps, " | Volume Min: ", minVolume, " | Lotstep: ", lotStep);
      Print("Fixed volume to match with broker");        
      riskByLotSteps = lotStep;
   }
   Print("lots: ", riskByLotSteps, " Limit: ", volumeLimit, " | max: ", maxVolume, " | min: ", minVolume, " | Lotstep: ", lotStep);
   return MathFloor(riskByLotSteps / lotStep) * lotStep;    
}


void ExcuteBuy(double entry, const double &ask){
   if(ask > entry - pullbackPoints * _POINT) return;
   
   double sl = NormalizeDouble(entry - slPoints * _POINT, _DIGITS);
   double tp = NormalizeDouble(entry + tpPoints * _POINT, _DIGITS);
   double slPoi = MathRound((entry - sl) / _POINT);
   double lots = 0.01;

   if(riskPercents > 0) lots = CalcLots(slPoi); //SL by % risk
   
   datetime expiration = iTime(_SYMBOL, mainTf, 0) + expirationBars * PeriodSeconds(mainTf);
   
   if(!trade.BuyStop(lots, entry, _SYMBOL, sl, tp, ORDER_TIME_SPECIFIED, expiration, commentary)){
      Print("BUYSTOP Failed | ", trade.ResultRetcode(), ": ", trade.ResultRetcodeDescription(), 
         " | Volume: ", lots, " ", _SYMBOL, 
         " | Entry: ", entry, 
         " | SL: ", sl, 
         " | TP: ", tp
      ); 
      return;
   }
   Print("BUYSTOP Successful | Volume: ", lots, " ", _SYMBOL, 
      "| Entry: ", entry, 
      " | SL: ", sl, 
      " | TP: ", tp
   );          
}


void ExcuteSell(double entry, const double &bid){
   if(bid < entry + pullbackPoints * _POINT) return;
   
   double sl = NormalizeDouble(entry + slPoints * _POINT, _DIGITS);
   double tp = NormalizeDouble(entry - tpPoints * _POINT, _DIGITS);
   double slPoi = MathRound((sl - entry) / _POINT);
   double lots = 0.01;

   if(riskPercents > 0) lots = CalcLots(slPoi); //SL by % risk
   
   datetime expiration = iTime(_SYMBOL, mainTf, 0) + expirationBars * PeriodSeconds(mainTf);
   if(!trade.SellStop(lots, entry, _SYMBOL, sl, tp, ORDER_TIME_SPECIFIED, expiration, commentary)){
      Print( "SELLSTOP Failed | ", trade.ResultRetcode(), ": ", trade.ResultRetcodeDescription(), 
         " | Volume: ", lots, " ", _SYMBOL, 
         " | Entry: ", entry, 
         " | SL: ", sl, 
         " | TP: ", tp
      );  
      return;
   }
   Print("SELLSTOP Successful | Volume: ", lots, " ", _SYMBOL, 
      " | Entry: ", entry, 
      " | SL: ", sl, 
      " | TP: ", tp
   );    
}


void CloseAllPendingOrders(){
   for(int i = OrdersTotal() - 1; i >= 0; i--){
   ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket)){
         if(OrderGetString(ORDER_SYMBOL) == _SYMBOL && 
         OrderGetInteger(ORDER_MAGIC) == magicNumber){
            long type = OrderGetInteger(ORDER_TYPE);
            double price = NormalizeDouble(OrderGetDouble(ORDER_PRICE_OPEN), _DIGITS);
            if(trade.OrderDelete(ticket)){
               Print("Deleted Successful order ", type == ORDER_TYPE_BUY_STOP ? "BUY STOP" : "SELL STOP",
                  " at ", price, " | Ticket: ", ticket
               );
            }else{
               Print("Failed to Delete order ", type == ORDER_TYPE_BUY_STOP ? "BUY STOP" : "SELL STOP", 
                  " at ", price, " | Ticket: ", ticket, " | Error: ", GetLastError()
               );
            }
         }
      }
   }
   Print("Deleted all pending order");
}


void TrailStop(const double &ask, const double &bid){       
   for(int i = 0; i < PositionsTotal(); i++){
      ulong posTicket = PositionGetTicket(i);
      if(PositionSelectByTicket(posTicket)){      
         if(PositionGetString(POSITION_SYMBOL) != _SYMBOL) continue;
         if(PositionGetInteger(POSITION_MAGIC) != magicNumber) continue;
         
         double posOP = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN), _DIGITS);
         double posSL = NormalizeDouble(PositionGetDouble(POSITION_SL), _DIGITS);        
         double posTP = NormalizeDouble(PositionGetDouble(POSITION_TP), _DIGITS);    
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            buyTotals++;
            if(bid > posOP + tslTriggerPoints * _POINT){
               double sl = bid - tslPoints * _POINT;
               sl = NormalizeDouble(sl, _DIGITS);
               
               if(sl > posSL || posSL == 0){
                  double tp = bid + tpPoints * _POINT;
                  tp = NormalizeDouble(tp, _DIGITS);
                  
                  if(!trade.PositionModify(posTicket, sl, tp)){ 
                     Print("MODIFY position Failed : ", trade.ResultRetcode(), " : ", trade.ResultRetcodeDescription());
                     Print("Buy Entry: ", posOP, 
                        " | SL: ", posSL, " -> ", sl, 
                        " | TP: ", posTP, " -> ", tp
                     );         
                  }
                  Print("MODIFY position Successful | Buy Entry: ", posOP, 
                     " | SL: ", posSL, " -> ", sl, 
                     " | TP: ", posTP, " -> ", tp
                  ); 
               }
            }
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            sellTotals++;
            if(ask < posOP - tslTriggerPoints * _POINT){
               double sl = ask + tslPoints * _POINT;
               sl = NormalizeDouble(sl, _DIGITS);
               if(sl < posSL || posSL == 0){
                  double tp = ask - tpPoints * _POINT;
                  tp = NormalizeDouble(tp, _DIGITS);
                  
                  if(!trade.PositionModify(posTicket, sl, tp)){ 
                     Print("MODIFY position Failed : ", trade.ResultRetcode(), " : ", trade.ResultRetcodeDescription());
                     Print("Sell Entry: ", posOP, 
                        " | SL: ", posSL, " -> ", sl, 
                        " | TP: ", posTP, " -> ", tp
                     );    
                  }
                  Print("MODIFY position Successful | Sell Entry: ", posOP, 
                     " | SL: ", posSL, " -> ", sl, 
                     " | TP: ", posTP, " -> ", tp
                  ); 
               }         
            }
         }
      }else Print("Failed to select position");
   }
}


string GetWeekdayName(const int &day){
   switch(day){
      case 0:
         return "Sunday(0)";
      case 1:
         return "Monday(1)";
      case 2:
         return "Tuesday(2)";
      case 3:
         return "Wednesday(3)";
      case 4:
         return "Thursday(4)";
      case 5:
         return "Friday(5)";
      case 6:
         return "Saturday(6)";
      default:
         return "INVALID DAY(" + IntegerToString(day) + ")";
   }
}


bool IsUpComingNews(const datetime &now){
   if(!newsFilterOn && !newsFilterByLv) return false;
   if(tradingDisableNews && now - lastNewsAvoided < startAfterMin * 60) return true; //1 minute = 60s
   
   tradingDisableNews = false;
   
   MqlCalendarValue values[];
   datetime endTime = now + daysNewsLookUp * 86400; //1 day = 86400s
   
   CalendarValueHistory(values, now, endTime, NULL, NULL);
   
   //find nearest news time
   datetime nearestNewsTime = LONG_MAX;
   int nearestNewsIndex = -1;
   
   for(int i = 0; i < ArraySize(values); i++) {
      if(values[i].time > now && values[i].time < nearestNewsTime){
         nearestNewsTime = values[i].time;
         nearestNewsIndex = i;
      }
   }
   
   if(nearestNewsIndex == -1) return false;
   
   //scan all news
   for(int i = 0; i < ArraySize(values); i++){
      if(values[i].time != values[nearestNewsIndex].time) continue;
      
      MqlCalendarEvent event;
      CalendarEventById(values[i].event_id, event);
      
      MqlCalendarCountry country;
      CalendarCountryById(event.country_id, country);
      
      //filter by Important Keywords
      if(newsFilterOn){
         for(int j = 0; j < keyTotals; j++){
            string currentEvent = newsToAvoid[j];
            StringToLower(currentEvent);
                   
            string currentNews = event.name;         
            StringToLower(currentNews);
                            
            if(StringFind(currentNews, currentEvent) < 0) continue;
                     
            Comment("Next News: ", country.currency, " | ", currentNews, " -> ", values[i].time);
            enabled_trading_label.Text("Disable trading by News");
            enabled_trading_label.Color(clrRed);
                        
            if(values[i].time - now < stopBeforeMin * 60){ //1 minute = 60s
               lastNewsAvoided = values[nearestNewsIndex].time;
               tradingDisableNews = true;
               if(tradingEnabledCmt == "" ||  tradingEnabledCmt != "Printed"){
                  tradingEnabledCmt = "DISABLED trading by upcoming news: " + currentNews;              
               }
               return true;
            }
         }
      } 
      
      //filter by Optional keywords + Important level
      if(newsFilterByLv){ 
         for(int j = 0; j < optionalKeyTotals; j++){
            string currentEvent = newsToAvoid2[j];
            StringToLower(currentEvent);
                    
            if(event.importance < importantLv) continue;
                   
            string currentNews = event.name;         
            StringToLower(currentNews);
                    
            if(StringFind(currentNews, currentEvent) < 0) continue;         
            
            string currency = country.currency;
            StringToLower(currency);
            
            if(StringFind(newsCurrencies, currency) < 0) continue;
                  
            Comment("Next News: ", country.currency, " | ", currentNews, " -> ", values[i].time);
            enabled_trading_label.Text("Disable trading by News");
            enabled_trading_label.Color(clrRed);
            
            if(values[i].time - now < stopBeforeMin * 60){ //1 minute = 60s
               lastNewsAvoided = values[nearestNewsIndex].time;
               tradingDisableNews = true;
               if(tradingEnabledCmt == "" || tradingEnabledCmt != "Printed"){
                  tradingEnabledCmt = "DISABLED trading by upcoming news: " + currentNews;              
               }
               return true;
            }
         }
      } 
   }
   Comment("");
   return false; 
}


bool IsRsiFilter(){
   if(!rsiFilterOn) return false;
   
   double rsi[];
   CopyBuffer(handleRsi, _MAIN_LINE, 0, 1, rsi);   
   ArraySetAsSeries(rsi, true);
   
   double rsiNow = rsi[0];
   
   if(rsiNow > rsiOb || rsiNow < rsiOs){
      if(tradingEnabledCmt == "" || tradingEnabledCmt != "Printed"){
         tradingEnabledCmt = "DISABLED trading by RSI: " + DoubleToString(rsiNow, 1);
      }
      enabled_trading_label.Text("DISABLED trading by RSI: " + DoubleToString(rsiNow, 1));
      enabled_trading_label.Color(clrRed);
      return true;
   }
   
   return false;
}


bool IsMaFilter(const double &ask){
   if(!maFilterOn) return false;
   
   double ma[];
   CopyBuffer(handleMa, _MAIN_LINE, 0, 1, ma);
   ArraySetAsSeries(ma, true);
   
   double maNow = ma[0];
   
   if(ask > maNow * (1 + pctFromMa/100) || 
      ask < maNow * (1 - pctFromMa/100)
   ){  
      if(tradingEnabledCmt == "" || tradingEnabledCmt != "Printed"){
         tradingEnabledCmt = "DISABLED trading by MA: " + DoubleToString(maNow, 1);
      }
      enabled_trading_label.Text("DISABLED trading by MA: " + DoubleToString(maNow, 1));
      enabled_trading_label.Color(clrRed);
      return true;      
   }
   
   return false;
}


void UpdateSlTp(const double &ask){
//update SL TP for Crypto
   switch(systemChoice){
      case _BITCOIN:{
         pullbackPoints = ask * tpAsPct/2;
         tslPoints = ask * tpAsPct * tslAsPctOfTp / 100;
         tslTriggerPoints = ask * tpAsPct * tslTriggerPctOfTp / 100;
         slAtrFactor = slAtrFactorBit;
         tpAtrFactor = tpAtrFactorBit;
         break;
      }
      //update SL TP for Gold
      case _GOLD:{
         pullbackPoints = ask * tpAsPctGold/2;
         tslPoints = ask * tpAsPctGold * tslAsPctOfTpGold / 100;
         tslTriggerPoints = ask * tpAsPctGold * tslTriggerPctOfTpGold / 100;
         slAtrFactor = slAtrFactorGold;
         tpAtrFactor = tpAtrFactorGold;
         break;
      }
      //update SL TP for Indices
      case _INDICIES:{
         //pullbackPoints = ask * tpAsPctIndicies/2;
         pullbackPoints = 100;
         tslPoints = ask * tpAsPctIndicies * tslAsPctOfTpIndicies / 100;
         tslTriggerPoints = ask * tpAsPctIndicies * tslTriggerPctOfTpIndicies / 100;
         slAtrFactor = slAtrFactorIndicies;
         tpAtrFactor = tpAtrFactorIndicies;
         break;
      }   
      //default forex
      default:{
         double sma[];
         CopyBuffer(handleSma, _MAIN_LINE, 1, 1, sma);
         pullbackPoints = MathRound(pullbackFactorFx * (sma[0] / _POINT) / 1000);
         //pullbackPoints = 140;
         break;
      }
   }

   pullbackPoints = MathRound(pullbackPoints);
   tslPoints = MathRound(tslPoints);
   tslTriggerPoints = MathRound(tslTriggerPoints);
   
   slPoints = MathRound(slAtrFactor * atrClosed / _POINT);
   tpPoints = MathRound(tpAtrFactor * atrClosed / _POINT);
}

//check trading weekday
bool IsTradingDay(const int &today){
   if(today < startWeekDay || today > endWeekDay){
      enabled_trading_label.Text("DISABLED trading by Out of trading Days");
      enabled_trading_label.Color(clrRed);
      
      if(isValidDay){
         Print("Out of trading weekdays: ", GetWeekdayName(today), 
            " | Trading weekdays: ", GetWeekdayName(startWeekDay), " - ", GetWeekdayName(endWeekDay)
         );
         CloseAllPendingOrders();
         ChartSetInteger(0, CHART_COLOR_BACKGROUND, chartColorTradingOff);
         offChat = true;
         isValidDay = false;
      }
      return false;         
   }
   isValidDay = true;
   return true;
}

//check trading hour 
bool IsTradingHour(const int &nowHour, const int &nowMin){ 
   if(!IsInTimeZone(startLd, endLd, nowHour, nowMin) && !IsInTimeZone(startNy, endNy, nowHour, nowMin)){
      if(isValidTime){
         Print("Out of trading hours: ", StringFormat("%02d:%02d", nowHour, nowMin), 
            " | Trading hours 1: ", StringFormat("%02d:%02d", startLd, 0), "-", StringFormat("%02d:%02d", endLd, 0), 
            " | Trading hours 2: ", StringFormat("%02d:%02d", startNy, 0), "-", StringFormat("%02d:%02d", endNy, 0)
         );
         CloseAllPendingOrders();
         ChartSetInteger(0, CHART_COLOR_BACKGROUND, chartColorTradingOff);
         offChat = true;
         isValidTime = false;
      }
      enabled_trading_label.Text("DISABLED trading by Out of trading Hours");
      enabled_trading_label.Color(clrRed);
      return false;
   }
   
   if(excTime1 && IsInTimeZone(exc1S, exc1E, nowHour, nowMin)){
      enabled_trading_label.Text("DISABLED trading by In Excepted Hours");
      enabled_trading_label.Color(clrRed);
      
      if(isValidTime){
         Print("In excepted time: ", StringFormat("%02d:%02d", nowHour, nowMin), 
            " | Excepted time 1: ", StringFormat("%02d:%02d", exc1S, 0), "-", StringFormat("%02d:%02d", exc1E, 0)
         );
         CloseAllPendingOrders();
         ChartSetInteger(0, CHART_COLOR_BACKGROUND, chartColorTradingOff);
         offChat = true;
         isValidTime = false;
      }
      return false;      
   }
   
   if(excTime2 && IsInTimeZone(exc2S, exc2E, nowHour, nowMin)){
      enabled_trading_label.Text("DISABLED trading by In Excepted Hours");
      enabled_trading_label.Color(clrRed);
      
      if(isValidTime){
         Print("In excepted time: ", StringFormat("%02d:%02d", nowHour, nowMin), 
            " | Excepted time 1: ", StringFormat("%02d:%02d", exc2S, 0), "-", StringFormat("%02d:%02d", exc2E, 0)
         );
         CloseAllPendingOrders();
         ChartSetInteger(0, CHART_COLOR_BACKGROUND, chartColorTradingOff);
         offChat = true;
         isValidTime = false;
      }
      return false;      
   }
      
   isValidTime = true;
   return true;   
}


//check spread
bool IsGoodSpread(const double &spread){
   if(spread > maxSpreadPoints){
      enabled_trading_label.Text("DISABLED trading by Spread too Large: " + DoubleToString(spread, 1));
      enabled_trading_label.Color(clrRed);
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, chartColorTradingOff);
      offChat = true;
      if(isValidSpread){
         Print("Spread too large: ", spread, " | Max spread: ", maxSpreadPoints);
         CloseAllPendingOrders();     
         isValidSpread = false;

      }
      return false;      
   }   
   isValidSpread = true;
   return true;
}

//check filter
bool CheckFilter(const double &ask, const datetime &now){
   if(IsUpComingNews(now) || IsMaFilter(ask) || IsRsiFilter()){
      if(tradingEnabledCmt != "Printed"){
         Print(tradingEnabledCmt);
         CloseAllPendingOrders();
         tradingEnabledCmt = "Printed";
         ChartSetInteger(0, CHART_COLOR_BACKGROUND, chartColorTradingOff);
         offChat = true;
      }    
      tradingEnabled = false;
      return true;
   }
   return false;
}


bool CountOrder(){
   for(int i = OrdersTotal() - 1; i >= 0; i--){
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket)){          
         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP && 
            OrderGetString(ORDER_SYMBOL) == _SYMBOL && 
            OrderGetInteger(ORDER_MAGIC) == magicNumber
         ){
            buyTotals++;
            lastBuyStopEntry = OrderGetDouble(ORDER_PRICE_OPEN);
         }
          
         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP && 
            OrderGetString(ORDER_SYMBOL) == _SYMBOL && 
            OrderGetInteger(ORDER_MAGIC) == magicNumber
         ){
            sellTotals++;
            lastSellStopEntry = OrderGetDouble(ORDER_PRICE_OPEN);
         }
         
      }else{ 
         Print("Failed to Select Order");
         Print("Can NOT count pending order -> Skip this bar");
         return false;
      }
   }
   return true;
}


void UpdateSpreadSlippage(const double &spread, const double &ask){
   switch(systemChoice){
      //update SL TP for Crypto
      case _BITCOIN:{
         maxSpreadPoints = ask * tpAsPct * maxSpreadPctOfTpBit  / 100;
         //maxSpreadPoints = 800;
         maxSlippagePoints = MathRound(maxSlippagePointsBit - spread);
         break;
      }
      //update SL TP for Gold
      case _GOLD:{
         //maxSpreadPoints = ask * tpAsPctGold * maxSpreadPctOfTpGold  / 100;
         maxSpreadPoints =  maxSpreadPointsGold;
         maxSlippagePoints = MathRound(maxSlippagePointsGold - spread);
         break;
      }
      //update SL TP for Indices
      case _INDICIES:{
         //maxSpreadPoints = ask * tpAsPctIndicies * maxSpreadPctOfTpIndicies  / 100;
         maxSpreadPoints = maxSpreadPointsIndices;
         maxSlippagePoints = MathRound(maxSlippagePointsIndicies - spread);
         break;
      }   
      //default forex
      default:{
         maxSpreadPoints   = maxSpreadPointsFx;
         maxSlippagePoints = MathRound(maxSlippagePointsFx - spread);
         break;
      }
   }
}


void CheckSlippage(const double &buySlippage, const double &sellSlippage){
   if(lastBuyStopEntry != 0 && buySlippage > maxSlippagePoints){
      CloseAllPendingOrders();
      Print("Slippage too large | Buy Slippage: ", buySlippage, " | Max Slippage: ", maxSlippagePoints);
      Print("Closed all pending order");
   }
   if(lastSellStopEntry != 0 && sellSlippage > maxSlippagePoints){
      CloseAllPendingOrders();
      Print("Slippage too large | Sell Slippage: ", sellSlippage, " | Max Slippage: ", maxSlippagePoints);
      Print("Closed all pending order");
   }
}


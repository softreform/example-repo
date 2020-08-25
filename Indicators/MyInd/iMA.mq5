//+------------------------------------------------------------------+ 
//|                                                     Demo_iMA.mq5 | 
//|                        Copyright 2011, MetaQuotes Software Corp. | 
//|                                             https://www.mql5.com | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright 2011, MetaQuotes Software Corp." 
#property link      "https://www.mql5.com" 
#property version   "1.00" 
#property description "Индикатор демонстрирует как нужно получать данные" 
#property description "индикаторных буферов для технического индикатора iMA." 
#property description "Символ и таймфрейм, на котором рассчитывается индикатор," 
#property description "задаются параметрами symbol и period." 
#property description "Способ создания хэндла задается параметром 'type' (тип функции)." 
#property description "Все остальные параметры как в стандартном Moving Average." 
  
#property indicator_chart_window 
#property indicator_buffers 1 
#property indicator_plots   1 
//--- построение iMA 
#property indicator_label1  "iMA" 
#property indicator_type1   DRAW_LINE 
#property indicator_color1  clrRed 
#property indicator_style1  STYLE_SOLID 
#property indicator_width1  1 
//+------------------------------------------------------------------+ 
//| Перечисление способов создания хэндла                            | 
//+------------------------------------------------------------------+ 
enum Creation 
  { 
   Call_iMA,               // использовать iMA 
   Call_IndicatorCreate    // использовать IndicatorCreate 
  }; 
//--- входные параметры 
input Creation             type=Call_iMA;                // тип функции  
input int                  ma_period=10;                 // период средней 
input int                  ma_shift=0;                   // смещение 
input ENUM_MA_METHOD       ma_method=MODE_SMA;           // тип сглаживания 
input ENUM_APPLIED_PRICE   applied_price=PRICE_CLOSE;    // тип цены 
input string               symbol=" ";                   // символ  
input ENUM_TIMEFRAMES      period=PERIOD_CURRENT;        // таймфрейм 
//--- индикаторный буфер 
double         iMABuffer[]; 
//--- переменная для хранения хэндла индикатора iMA 
int    handle; 
//--- переменная для хранения  
string name=symbol; 
//--- имя индикатора на графике 
string short_name; 
//--- будем хранить количество значений в индикаторе Moving Average 
int    bars_calculated=0; 
//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit() 
  { 
//--- привязка массива к индикаторному буферу 
   SetIndexBuffer(0,iMABuffer,INDICATOR_DATA); 
//--- зададим смещение 
   PlotIndexSetInteger(0,PLOT_SHIFT,ma_shift);    
//--- определимся с символом, на котором строится индикатор    
   name=symbol; 
//--- удалим пробелы слева и справа 
   StringTrimRight(name); 
   StringTrimLeft(name); 
//--- если после этого длина строки name нулевая 
   if(StringLen(name)==0) 
     { 
      //--- возьмем символ с графика, на котором запущен индикатор 
      name=_Symbol; 
     } 
//--- создадим хэндл индикатора 
   if(type==Call_iMA) 
      handle=iMA(name,period,ma_period,ma_shift,ma_method,applied_price); 
   else 
     { 
      //--- заполним структуру значениями параметров индикатора 
      MqlParam pars[4]; 
      //--- период 
      pars[0].type=TYPE_INT; 
      pars[0].integer_value=ma_period; 
      //--- смещение 
      pars[1].type=TYPE_INT; 
      pars[1].integer_value=ma_shift; 
      //--- тип сглаживания 
      pars[2].type=TYPE_INT; 
      pars[2].integer_value=ma_method; 
      //--- тип цены 
      pars[3].type=TYPE_INT; 
      pars[3].integer_value=applied_price; 
      handle=IndicatorCreate(name,period,IND_MA,4,pars); 
     } 
//--- если не удалось создать хэндл 
   if(handle==INVALID_HANDLE) 
     { 
      //--- сообщим о неудаче и выведем номер ошибки 
      PrintFormat("Не удалось создать хэндл индикатора iMA для пары %s/%s, код ошибки %d", 
                  name, 
                  EnumToString(period), 
                  GetLastError()); 
      //--- работа индикатора завершается досрочно 
      return(INIT_FAILED); 
     } 
//--- покажем на какой паре символ/таймфрейм рассчитан индикатор Moving Average 
   short_name=StringFormat("iMA(%s/%s, %d, %d, %s, %s)",name,EnumToString(period), 
                           ma_period, ma_shift,EnumToString(ma_method),EnumToString(applied_price)); 
   IndicatorSetString(INDICATOR_SHORTNAME,short_name); 
//--- нормальное выполнение инициализации индикатора 
   return(INIT_SUCCEEDED); 
  } 
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total, 
                const int prev_calculated, 
                const datetime &time[], 
                const double &open[], 
                const double &high[], 
                const double &low[], 
                const double &close[], 
                const long &tick_volume[], 
                const long &volume[], 
                const int &spread[]) 
  { 
//--- количество копируемых значений из индикатора iMA 
   int values_to_copy; 
//--- узнаем количество рассчитанных значений в индикаторе 
   int calculated=BarsCalculated(handle); 
   if(calculated<=0) 
     { 
      PrintFormat("BarsCalculated() вернул %d, код ошибки %d",calculated,GetLastError()); 
      return(0); 
     } 
//--- если это первый запуск вычислений нашего индикатора или изменилось количество значений в индикаторе iMA 
//--- или если необходимо рассчитать индикатор для двух или более баров (значит что-то изменилось в истории) 
   if(prev_calculated==0 || calculated!=bars_calculated || rates_total>prev_calculated+1) 
     { 
      //--- если массив iMABuffer больше, чем значений в индикаторе iMA на паре symbol/period, то копируем не все  
      //--- в противном случае копировать будем меньше, чем размер индикаторных буферов 
      if(calculated>rates_total) values_to_copy=rates_total; 
      else                       values_to_copy=calculated; 
     } 
   else 
     { 
      //--- значит наш индикатор рассчитывается не в первый раз и с момента последнего вызова OnCalculate()) 
      //--- для расчета добавилось не более одного бара 
      values_to_copy=(rates_total-prev_calculated)+1; 
     } 
//--- заполняем массив iMABuffer  значениями из индикатора Moving Average 
//--- если FillArrayFromBuffer вернула false, значит данные не готовы - завершаем работу 
   if(!FillArrayFromBuffer(iMABuffer,ma_shift,handle,values_to_copy)) return(0); 
//--- сформируем сообщение 
   string comm=StringFormat("%s ==>  Обновлено значений в индикаторе %s: %d", 
                            TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS), 
                            short_name, 
                            values_to_copy); 
//--- выведем на график служебное сообщение 
   Comment(comm); 
//--- запомним количество значений в индикаторе Moving Average 
   bars_calculated=calculated; 
//--- вернем значение prev_calculated для следующего вызова 
   return(rates_total); 
  } 
//+------------------------------------------------------------------+ 
//| Заполняем индикаторный буфер из индикатора iMA                   | 
//+------------------------------------------------------------------+ 
bool FillArrayFromBuffer(double &values[],   // индикаторный буфер значений Moving Average 
                         int shift,          // смещение 
                         int ind_handle,     // хэндл индикатора iMA 
                         int amount          // количество копируемых значений 
                         ) 
  { 
//--- сбросим код ошибки 
   ResetLastError(); 
//--- заполняем часть массива iMABuffer значениями из индикаторного буфера под индексом 0 
   if(CopyBuffer(ind_handle,0,-shift,amount,values)<0) 
     { 
      //--- если копирование не удалось, сообщим код ошибки 
      PrintFormat("Не удалось скопировать данные из индикатора iMA, код ошибки %d",GetLastError()); 
      //--- завершим с нулевым результатом - это означает, что индикатор будет считаться нерассчитанным 
      return(false); 
     } 
//--- все получилось 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Indicator deinitialization function                              | 
//+------------------------------------------------------------------+ 
void OnDeinit(const int reason) 
  { 
   if(handle!=INVALID_HANDLE) 
      IndicatorRelease(handle); 
//--- почистим график при удалении индикатора 
   Comment(""); 
  }     
 

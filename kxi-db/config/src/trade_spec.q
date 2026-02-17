// generate some apple trade data with an initial price of 200
prices:200;
syms:`AAPL;

// add some randomess to price changes per update
drift:{(rand -1 1)*0.001*1?1.}

// simple function to generate data with a slight drift up/or down randomly
genData:{[]
  p:prices*(1-drift[]);
  size:1?100*1+til 10;
  side:1?`BUY`SELL;
  data:flip (!) . flip (
    (`time;.z.P);
    (`sym;syms);
    (`price;p);
    (`size;size);
    (`side;side)
    );
  `prices set p;
  :data;
  };

base:.qsp.read.fromCallback[`publishTrade]
    .qsp.map[{[data] `time`spTime xcols update spTime:.z.P from data}]
    .qsp.split[]

rawTrade:base .qsp.v2.write.toDatabase[`trade; .qsp.use (!) . flip (
      (`target     ; "kxi-sm:10001");
      (`overwrite   ; 0b)
      )]

ohlc:base .qsp.window.timer[00:00:10]
    .qsp.map[{[data] 
      select time:last time,
        spTime:last spTime,
        sym:last sym,
        high:max price, 
        low:min price, 
        open:first price, 
        close:last price,
        volume:sum size
      from data
      }]
    .qsp.v2.write.toDatabase[`ohlc; .qsp.use (!) . flip (
      (`target     ; "kxi-sm:10001");
      (`overwrite   ; 0b)
      )]

.qsp.run (rawTrade; ohlc)

/timer functions
pub:{
    publishTrade genData[];
    };

.qsp.onStart {
    // Send a message every 100 ms
    .tm.add[`pub; (`pub; ()); 100; 0]
    };

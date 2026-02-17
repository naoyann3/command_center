# Build script: Extract raw data from original file and create command-center.html

$originalFile = Join-Path $PSScriptRoot "rsi_rational-greed.html"
$outputFile = Join-Path $PSScriptRoot "command-center.html"

# Extract raw data (lines 106-1507 contain the rawTextData content)
$lines = Get-Content $originalFile -Encoding UTF8
$rawDataLines = $lines[105..1506] # 0-indexed: line 106-1507
$rawDataBlock = ($rawDataLines -join "`n")

# Build the HTML
$htmlTop = @'
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>COMMAND CENTER — Rational Greed v6.0</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="https://cdn.jsdelivr.net/npm/luxon"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-luxon"></script>
<link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Roboto+Mono:wght@400;500;700&family=Inter:wght@400;700&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box;}
:root{
  --bg-primary:#0a0e14;--bg-panel:#111820;--bg-card:#161e2a;
  --border:#1e2a3a;--border-accent:#2a3a4a;
  --text-primary:#c8d6e5;--text-secondary:#6b7d8e;--text-dim:#3a4a5a;
  --accent-green:#00ff88;--accent-red:#ff3344;--accent-amber:#ffaa00;
  --accent-cyan:#00ccff;--accent-blue:#3366ff;
  --glow-green:0 0 12px rgba(0,255,136,0.3);--glow-red:0 0 12px rgba(255,51,68,0.3);
}
html,body{height:100%;font-family:'Roboto Mono',monospace;background:var(--bg-primary);color:var(--text-primary);overflow-x:hidden;}
.mono{font-family:'Roboto Mono',monospace;}

/* HEADER */
.cmd-header{
  background:linear-gradient(180deg,#0d1117 0%,#0a0e14 100%);
  border-bottom:1px solid var(--border);padding:12px 24px;
  display:flex;justify-content:space-between;align-items:center;
}
.cmd-title{font-family:'Share Tech Mono',monospace;font-size:18px;color:var(--accent-green);letter-spacing:4px;text-transform:uppercase;}
.cmd-title span{color:var(--accent-red);font-size:10px;margin-left:8px;padding:2px 6px;border:1px solid var(--accent-red);border-radius:2px;}
.cmd-status{font-size:10px;color:var(--text-secondary);display:flex;gap:16px;align-items:center;}
.cmd-status .live{color:var(--accent-green);animation:blink 1.5s infinite;}
@keyframes blink{0%,100%{opacity:1;}50%{opacity:0.3;}}
.scanline{position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:9999;
  background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,136,0.015) 2px,rgba(0,255,136,0.015) 4px);}

/* GRID */
.dashboard-grid{display:grid;grid-template-columns:1fr 2fr 1fr;gap:2px;height:calc(100vh - 52px);padding:2px;}
@media(max-width:1200px){.dashboard-grid{grid-template-columns:1fr;grid-template-rows:auto;height:auto;}}

/* PANELS */
.panel{background:var(--bg-panel);border:1px solid var(--border);position:relative;overflow:hidden;display:flex;flex-direction:column;}
.panel-header{
  padding:8px 14px;border-bottom:1px solid var(--border);
  display:flex;justify-content:space-between;align-items:center;
  background:linear-gradient(90deg,rgba(0,255,136,0.05) 0%,transparent 100%);
}
.panel-label{font-family:'Share Tech Mono',monospace;font-size:11px;color:var(--accent-green);letter-spacing:3px;text-transform:uppercase;}
.panel-tag{font-size:9px;color:var(--text-dim);border:1px solid var(--border-accent);padding:1px 6px;border-radius:2px;}
.panel-body{flex:1;overflow:auto;padding:8px;}
.panel-body::-webkit-scrollbar{width:4px;}
.panel-body::-webkit-scrollbar-track{background:var(--bg-primary);}
.panel-body::-webkit-scrollbar-thumb{background:var(--border-accent);border-radius:2px;}

/* HEATMAP */
.heatmap-frame{width:100%;height:100%;border:none;filter:brightness(0.9) contrast(1.05);}

/* ASSET BUTTONS */
.btn-grid{display:flex;flex-wrap:wrap;gap:4px;margin-bottom:8px;}
.btn-asset{
  background:var(--bg-card);border:1px solid var(--border);color:var(--text-secondary);
  padding:4px 10px;font-size:10px;font-family:'Roboto Mono',monospace;cursor:pointer;
  transition:all 0.15s;border-radius:2px;
}
.btn-asset:hover{border-color:var(--accent-cyan);color:var(--accent-cyan);}
.btn-asset.active{background:rgba(0,255,136,0.1);border-color:var(--accent-green);color:var(--accent-green);box-shadow:var(--glow-green);}

/* CONTROLS */
.ctrl-row{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:8px;padding:6px 10px;background:var(--bg-card);border:1px solid var(--border);border-radius:2px;}
.ctrl-label{font-size:9px;color:var(--text-dim);text-transform:uppercase;letter-spacing:1px;}
.ctrl-input{
  background:var(--bg-primary);border:1px solid var(--border);color:var(--accent-amber);
  padding:4px 8px;width:90px;font-family:'Roboto Mono',monospace;font-size:12px;border-radius:2px;
}
.currency-btn{
  background:var(--bg-primary);border:1px solid var(--border);color:var(--text-secondary);
  padding:4px 10px;font-size:10px;font-family:'Roboto Mono',monospace;cursor:pointer;border-radius:2px;transition:all 0.15s;
}
.currency-btn.active{background:rgba(0,255,136,0.1);border-color:var(--accent-green);color:var(--accent-green);}

/* RSI CHART */
.chart-container{position:relative;height:55%;min-height:280px;width:100%;}
.rsi-signal{display:flex;align-items:center;gap:6px;font-size:10px;color:var(--accent-red);padding:4px 10px;background:rgba(255,51,68,0.08);border:1px solid rgba(255,51,68,0.2);border-radius:2px;margin-bottom:8px;}

/* DCA RESULTS */
.dca-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:6px;margin-top:8px;}
.dca-card{
  background:var(--bg-card);border:1px solid var(--border);border-left:3px solid var(--accent-cyan);
  padding:10px 12px;border-radius:2px;
}
.dca-card .ticker{font-size:12px;font-weight:700;color:var(--text-primary);}
.dca-card .pct{font-size:11px;padding:1px 6px;border-radius:2px;}
.dca-card .pct.pos{background:rgba(0,255,136,0.1);color:var(--accent-green);}
.dca-card .pct.neg{background:rgba(255,51,68,0.1);color:var(--accent-red);}
.dca-card .row{display:flex;justify-content:space-between;font-size:9px;color:var(--text-secondary);margin-top:4px;}
.dca-card .val{color:var(--text-primary);}

/* TRADINGVIEW PANEL */
.tv-section{margin-bottom:12px;}
.tv-section-title{font-size:10px;color:var(--accent-cyan);letter-spacing:2px;text-transform:uppercase;margin-bottom:6px;padding-bottom:4px;border-bottom:1px solid var(--border);}
.tv-widget-container{width:100%;min-height:300px;margin-bottom:8px;}
.fundamentals-table{width:100%;border-collapse:collapse;font-size:10px;}
.fundamentals-table th{text-align:left;color:var(--text-dim);font-weight:400;padding:6px 8px;border-bottom:1px solid var(--border);text-transform:uppercase;letter-spacing:1px;font-size:9px;}
.fundamentals-table td{padding:6px 8px;border-bottom:1px solid rgba(30,42,58,0.5);color:var(--text-primary);}
.fundamentals-table tr:hover{background:rgba(0,204,255,0.03);}
.ticker-badge{display:inline-block;padding:1px 6px;border-radius:2px;font-weight:700;font-size:10px;margin-right:4px;}
.ticker-btc{background:rgba(249,115,22,0.15);color:#f97316;border:1px solid rgba(249,115,22,0.3);}
.ticker-nvda{background:rgba(16,185,129,0.15);color:#10b981;border:1px solid rgba(16,185,129,0.3);}
.ticker-slv{background:rgba(148,163,184,0.15);color:#94a3b8;border:1px solid rgba(148,163,184,0.3);}

/* MINI CHARTS */
.tv-mini{width:100%;height:220px;border:1px solid var(--border);border-radius:2px;overflow:hidden;margin-bottom:6px;}

/* LOADING */
.loading-overlay{position:absolute;inset:0;background:rgba(10,14,20,0.95);display:flex;align-items:center;justify-content:center;z-index:20;}
.loading-spinner{width:30px;height:30px;border:2px solid var(--border);border-top-color:var(--accent-green);border-radius:50%;animation:spin 0.8s linear infinite;}
@keyframes spin{to{transform:rotate(360deg);}}
.loading-text{color:var(--accent-green);font-size:11px;margin-top:8px;letter-spacing:2px;}
</style>
</head>
<body>
<div class="scanline"></div>

<!-- HEADER -->
<header class="cmd-header">
  <div class="cmd-title">⬡ COMMAND CENTER <span>v6.0</span></div>
  <div class="cmd-status">
    <span class="live">● LIVE</span>
    <span id="clock"></span>
  </div>
</header>

<!-- DASHBOARD -->
<div class="dashboard-grid">

  <!-- LEFT: FINVIZ HEATMAP -->
  <div class="panel">
    <div class="panel-header">
      <span class="panel-label">◈ Sector Heatmap</span>
      <span class="panel-tag">FINVIZ 1M</span>
    </div>
    <div class="panel-body" style="padding:0;">
      <iframe class="heatmap-frame" src="https://finviz.com/map.ashx?t=sec&st=w4" title="Finviz Heatmap"></iframe>
    </div>
  </div>

  <!-- CENTER: RSI ENGINE -->
  <div class="panel">
    <div class="panel-header">
      <span class="panel-label">◈ RSI Signal Engine</span>
      <span class="panel-tag">WEEKLY RSI-14</span>
    </div>
    <div class="panel-body">
      <div class="rsi-signal">
        <span style="font-size:14px;">◆</span> 週足RSI &lt; 35 = 買いシグナル検出
      </div>
      <div class="btn-grid" id="asset-buttons"></div>
      <div class="ctrl-row">
        <div><span class="ctrl-label">通貨</span>
          <div style="display:flex;gap:4px;margin-top:3px;">
            <button id="currency-usd" class="currency-btn active">USD</button>
            <button id="currency-jpy" class="currency-btn">JPY</button>
          </div>
        </div>
        <div><span class="ctrl-label">毎週積立額</span>
          <input type="number" id="dca-amount" value="100" class="ctrl-input">
        </div>
      </div>
      <div class="chart-container">
        <canvas id="mainChart"></canvas>
        <div id="loading" class="loading-overlay">
          <div style="text-align:center;">
            <div class="loading-spinner"></div>
            <div class="loading-text">CALIBRATING...</div>
          </div>
        </div>
      </div>
      <div class="dca-grid" id="dca-results"></div>
    </div>
  </div>

  <!-- RIGHT: TRADINGVIEW -->
  <div class="panel">
    <div class="panel-header">
      <span class="panel-label">◈ Fundamentals</span>
      <span class="panel-tag">BTC / NVDA / SLV</span>
    </div>
    <div class="panel-body">
      <div class="tv-section">
        <div class="tv-section-title">Key Metrics</div>
        <table class="fundamentals-table">
          <thead><tr><th>Ticker</th><th>Type</th><th>PER</th><th>Div Yield</th></tr></thead>
          <tbody>
            <tr><td><span class="ticker-badge ticker-btc">BTC</span></td><td style="color:var(--text-secondary)">Crypto</td><td style="color:var(--text-dim)">N/A</td><td style="color:var(--text-dim)">N/A</td></tr>
            <tr><td><span class="ticker-badge ticker-nvda">NVDA</span></td><td style="color:var(--text-secondary)">Stock</td><td id="nvda-per" style="color:var(--accent-amber)">—</td><td id="nvda-div" style="color:var(--accent-green)">—</td></tr>
            <tr><td><span class="ticker-badge ticker-slv">SLV</span></td><td style="color:var(--text-secondary)">ETF</td><td style="color:var(--text-dim)">N/A</td><td id="slv-div" style="color:var(--accent-green)">—</td></tr>
          </tbody>
        </table>
      </div>
      <div class="tv-section">
        <div class="tv-section-title">BTC/USD</div>
        <div class="tv-mini" id="tv-btc"></div>
      </div>
      <div class="tv-section">
        <div class="tv-section-title">NVDA</div>
        <div class="tv-mini" id="tv-nvda"></div>
      </div>
      <div class="tv-section">
        <div class="tv-section-title">SLV</div>
        <div class="tv-mini" id="tv-slv"></div>
      </div>
    </div>
  </div>
</div>

<script>
// Clock
function updateClock(){const now=new Date();document.getElementById('clock').textContent=now.toLocaleString('ja-JP',{year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit'});}
setInterval(updateClock,1000);updateClock();

// TradingView Mini Charts
function loadTVWidget(containerId, symbol){
  const container = document.getElementById(containerId);
  container.innerHTML = '';
  const script = document.createElement('script');
  script.src = 'https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js';
  script.async = true;
  script.textContent = JSON.stringify({
    "symbol": symbol,
    "width": "100%",
    "height": "100%",
    "locale": "ja",
    "dateRange": "1M",
    "colorTheme": "dark",
    "isTransparent": true,
    "autosize": true,
    "largeChartUrl": "",
    "noTimeScale": false,
    "chartOnly": false
  });
  container.appendChild(script);
}
loadTVWidget('tv-btc','BITSTAMP:BTCUSD');
loadTVWidget('tv-nvda','NASDAQ:NVDA');
loadTVWidget('tv-slv','AMEX:SLV');

// Fetch fundamentals via TradingView symbol info (static fallback)
document.getElementById('nvda-per').textContent = '~54.2';
document.getElementById('nvda-div').textContent = '~0.03%';
document.getElementById('slv-div').textContent = '~0.00%';

/**
 * =================================================================
 *  RAW DATA
 * =================================================================
 */
'@

$htmlMid = @'

/**
 * =================================================================
 *  CORE LOGIC
 * =================================================================
 */
function generateWeeklyTimeline(){
  const t=[];let c=new Date(2021,0,1);
  while(c.getDay()!==5)c.setDate(c.getDate()+1);
  const e=new Date(2030,11,31);
  while(c<=e){t.push(new Date(c));c.setDate(c.getDate()+7);}
  return t;
}
const masterTimeline=generateWeeklyTimeline();

function parseAndAlignData(text){
  const assets={};const lines=text.trim().split('\n');
  let currentAsset=null,currentYear=null;const rawPoints={};
  for(let i=0;i<lines.length;i++){
    let line=lines[i].trim();if(!line)continue;
    if(/[a-zA-Z]/.test(line)&&!line.includes(',')&&!line.includes('年')){
      const m=line.match(/\((.*?)\)/);currentAsset=m?m[1]:line.split(' ')[0];rawPoints[currentAsset]=[];continue;
    }
    if(line.includes('年')&&!line.includes(',')){currentYear=parseInt(line.replace('年','').trim());continue;}
    if(currentAsset&&currentYear){
      const parts=line.match(/(\".*?\"|[^\",\s]+)(?=\s*,|\s*$)/g);
      if(parts){for(let j=0;j<parts.length;j+=2){
        let ds=parts[j]?parts[j].replace(/,/g,'').trim():null;
        let ps=parts[j+1]?parts[j+1].replace(/\"/g,'').trim():null;
        if(ds&&isNaN(parseInt(ds.split('/')[0]))){
          const em={Jan:1,Feb:2,Mar:3,Apr:4,May:5,Jun:6,Jul:7,Aug:8,Sep:9,Oct:10,Nov:11,Dec:12};
          const[mN,dV]=ds.split(' ');if(em[mN])ds=`${em[mN]}/${dV}`;
        }
        if(ds&&ps){const[m,d]=ds.split('/').map(Number);const date=new Date(currentYear,m-1,d);
          const price=parseFloat(ps.replace(/,/g,''));
          if(!isNaN(price)&&price>0)rawPoints[currentAsset].push({date,price});
        }
      }}
    }
  }
  Object.keys(rawPoints).forEach(a=>{
    rawPoints[a].sort((x,y)=>x.date-y.date);if(!rawPoints[a].length)return;
    const aligned=[];let last=rawPoints[a][0].price;const lastDate=rawPoints[a][rawPoints[a].length-1].date;
    masterTimeline.forEach(t=>{
      if(t>lastDate){aligned.push({x:t.toISOString(),y:null});return;}
      const n=rawPoints[a].find(p=>Math.abs(p.date-t)<4*864e5);if(n)last=n.price;
      if(t<rawPoints[a][0].date)aligned.push({x:t.toISOString(),y:null});
      else aligned.push({x:t.toISOString(),y:last});
    });
    assets[a]=aligned;
  });
  return assets;
}

function calculateRSI(dp){
  if(!dp||!dp.length)return[];const p=dp.map(x=>x.y);const per=14;const r=new Array(p.length).fill(null);
  let lp=null,g=0,l=0,c=0,i=0;
  for(;i<p.length;i++){if(p[i]===null)continue;if(lp===null){lp=p[i];continue;}
    const d=p[i]-lp;if(d>0)g+=d;else l-=d;lp=p[i];if(++c===per)break;}
  if(c<per)return r;let aG=g/per,aL=l/per;
  r[i]=100-(100/(1+(aG/(aL||1e-5))));
  for(let k=i+1;k<p.length;k++){if(p[k]===null)continue;const d=p[k]-lp;
    const gg=d>0?d:0,ll=d<0?-d:0;aG=(aG*13+gg)/14;aL=(aL*13+ll)/14;
    r[k]=100-(100/(1+(aG/(aL||1e-5))));lp=p[k];}
  return r;
}

function calculateSMA(data,period){
  return data.map((p,i)=>{if(p.y===null||i<period-1)return{x:p.x,y:null};
    let s=0,c=0;for(let j=0;j<period;j++){if(data[i-j].y!==null){s+=data[i-j].y;c++;}}
    return{x:p.x,y:c===period?s/period:null};});
}

const alignedAssets=parseAndAlignData(rawTextData);
let activeKeys=Object.keys(alignedAssets).filter(k=>k!=='USDJPY');
let selectedCurrency='USD';let myChart=null;

function updateDCASimulation(){
  const amount=parseFloat(document.getElementById('dca-amount').value)||0;
  const container=document.getElementById('dca-results');container.innerHTML='';
  const keys=activeKeys.filter(k=>k!=='USDJPY');const usd=alignedAssets['USDJPY'];
  let lastRate=110;if(usd){const f=usd.find(p=>p.y!==null);if(f)lastRate=f.y;}
  keys.forEach(key=>{
    const data=alignedAssets[key];if(!data)return;
    let tU=0,tIU=0,tIJ=0,vw=0,cr=lastRate;
    data.forEach((pt,idx)=>{if(usd[idx]&&usd[idx].y!==null)cr=usd[idx].y;
      if(pt.y!==null&&pt.y>0){let iU,iJ,u;
        if(selectedCurrency==='JPY'){iJ=amount;iU=amount/cr;u=iU/pt.y;}
        else{iU=amount;iJ=amount*cr;u=iU/pt.y;}
        tU+=u;tIU+=iU;tIJ+=iJ;vw++;}});
    if(!vw)return;
    const lv=[...data].reverse().find(p=>p.y!==null);const fU=lv.y;
    let lr=cr;const lrp=[...usd].reverse().find(p=>p.y!==null);if(lrp)lr=lrp.y;
    const vU=tU*fU,vJ=vU*lr;
    let pp,dI,dV;
    if(selectedCurrency==='JPY'){pp=((vJ-tIJ)/tIJ)*100;dI=tIJ;dV=vJ;}
    else{pp=((vU-tIU)/tIU)*100;dI=tIU;dV=vU;}
    const colorMap={'NVDA':'#10b981','BTC-USD':'#f97316','^GSPC':'#3b82f6','GLD':'#eab308','SLV':'#94a3b8','SMH':'#818cf8','TSM':'#60a5fa','ASML':'#1e40af','CRWD':'#06b6d4','PLTR':'#a855f7','AVGO':'#1e3a8a','AMD':'#ef4444','ITA':'#15803d'};
    const color=colorMap[key]||'#64748b';const sym=selectedCurrency==='JPY'?'¥':'$';
    const card=document.createElement('div');card.className='dca-card';card.style.borderLeftColor=color;
    card.innerHTML=`<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;">
      <span class="ticker">${key}</span>
      <span class="pct ${pp>=0?'pos':'neg'}">${pp>=0?'+':''}${pp.toFixed(1)}%</span>
    </div>
    <div class="row"><span>投資元本</span><span class="val">${sym}${dI.toLocaleString(undefined,{maximumFractionDigits:0})}</span></div>
    <div class="row"><span>評価額</span><span class="val">${sym}${dV.toLocaleString(undefined,{maximumFractionDigits:0})}</span></div>
    <div class="row"><span>投資週数</span><span class="val">${vw}週</span></div>
    <div class="row"><span>保有数量</span><span class="val">${tU.toFixed(4)}</span></div>`;
    container.appendChild(card);
  });
}

function renderChart(){
  const ctx=document.getElementById('mainChart').getContext('2d');const datasets=[];
  const dk=activeKeys.filter(k=>k!=='USDJPY');
  dk.forEach(key=>{
    const data=alignedAssets[key];const fv=data.find(p=>p.y!==null);const base=fv?fv.y:1;
    const norm=data.map(p=>({x:p.x,y:p.y===null?null:(p.y/base)*100}));
    const rsi=calculateRSI(data);const sma=calculateSMA(norm,40);
    const cm={'NVDA':'#10b981','BTC-USD':'#f97316','^GSPC':'#3b82f6','GLD':'#eab308','SLV':'#94a3b8','SMH':'#818cf8','TSM':'#60a5fa','ASML':'#1e40af','CRWD':'#06b6d4','PLTR':'#a855f7','AVGO':'#1e3a8a','AMD':'#ef4444','ITA':'#15803d'};
    const color=cm[key]||'#64748b';
    datasets.push({label:key,data:norm,borderColor:color,borderWidth:2,pointRadius:0,tension:0.1,order:2});
    datasets.push({label:'',data:sma,borderColor:color,borderWidth:1,borderDash:[3,3],pointRadius:0,tension:0.3,order:3});
    const sigs=norm.map((p,idx)=>(rsi[idx]!==null&&rsi[idx]<35)?p:null).filter(p=>p);
    if(sigs.length>0)datasets.push({label:'',data:sigs,backgroundColor:'#ff3344',borderColor:'#1a1a2e',borderWidth:1,pointStyle:'rectRot',pointRadius:6,showLine:false,order:1});
  });
  if(myChart)myChart.destroy();
  myChart=new Chart(ctx,{type:'line',data:{datasets},options:{
    responsive:true,maintainAspectRatio:false,
    interaction:{mode:'nearest',intersect:false,axis:'x'},
    plugins:{legend:{position:'bottom',labels:{usePointStyle:true,color:'#6b7d8e',font:{family:'Roboto Mono',size:10},filter:i=>i.text!==''}},
      tooltip:{backgroundColor:'#161e2a',borderColor:'#2a3a4a',borderWidth:1,titleColor:'#00ff88',bodyColor:'#c8d6e5',
        callbacks:{label:c=>c.dataset.label?`${c.dataset.label}: ${c.raw.y.toFixed(1)}%`:null}}},
    scales:{x:{type:'time',time:{unit:'month'},grid:{color:'rgba(30,42,58,0.5)'},ticks:{color:'#3a4a5a',font:{size:9}}},
      y:{grid:{color:'rgba(30,42,58,0.5)'},ticks:{color:'#3a4a5a',font:{size:9},callback:v=>(v-100)+'%'}}}
  }});
  document.getElementById('loading').style.display='none';
  updateDCASimulation();
}

function init(){
  const bc=document.getElementById('asset-buttons');
  Object.keys(alignedAssets).filter(k=>k!=='USDJPY').forEach(key=>{
    const btn=document.createElement('button');const m=key.match(/\((.*?)\)/);
    btn.textContent=m?m[1]:key.split(' ')[0];
    btn.className=`btn-asset ${activeKeys.includes(key)?'active':''}`;
    btn.onclick=()=>{if(activeKeys.includes(key))activeKeys=activeKeys.filter(k=>k!==key);
      else activeKeys.push(key);btn.classList.toggle('active');renderChart();};
    bc.appendChild(btn);
  });
  document.getElementById('currency-usd').onclick=e=>{selectedCurrency='USD';e.target.classList.add('active');document.getElementById('currency-jpy').classList.remove('active');updateDCASimulation();};
  document.getElementById('currency-jpy').onclick=e=>{selectedCurrency='JPY';e.target.classList.add('active');document.getElementById('currency-usd').classList.remove('active');updateDCASimulation();};
  document.getElementById('dca-amount').oninput=updateDCASimulation;
  renderChart();
}
window.onload=init;
</script>
</body>
</html>
'@

# Combine everything
$fullHtml = $htmlTop + "`n" + $rawDataBlock + "`n" + $htmlMid

# Write output
[System.IO.File]::WriteAllText($outputFile, $fullHtml, [System.Text.Encoding]::UTF8)

Write-Host "Dashboard created at: $outputFile"
Write-Host "File size: $((Get-Item $outputFile).Length) bytes"

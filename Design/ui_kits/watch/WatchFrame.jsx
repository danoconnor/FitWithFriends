/* WatchFrame.jsx — Apple Watch (45mm) bezel.
   Screen is designed at 198×242 points (45mm @2x ÷ 2). The whole frame scales
   up for legibility via the `scale` prop. watchOS canvas is black. */

function WatchFrame({ children, scale = 1.7 }) {
  const SW = 198, SH = 242;          // screen (points)
  const caseW = SW + 26, caseH = SH + 44;
  return (
    <div style={{ transform:`scale(${scale})`, transformOrigin:"center" }}>
      <div style={{ position:"relative", width:caseW, height:caseH }}>
        {/* digital crown */}
        <div style={{ position:"absolute", right:-5, top:caseH*0.30, width:7, height:34, borderRadius:4,
          background:"linear-gradient(90deg,#3a3a3c,#0b0b0c)", boxShadow:"0 1px 2px rgba(0,0,0,.5)" }}/>
        {/* side button */}
        <div style={{ position:"absolute", right:-3, top:caseH*0.52, width:4, height:46, borderRadius:3,
          background:"linear-gradient(90deg,#2a2a2c,#0b0b0c)" }}/>
        {/* case */}
        <div style={{ position:"absolute", inset:0, borderRadius:54,
          background:"linear-gradient(155deg,#2b2b2e,#0d0d0f 60%)",
          boxShadow:"0 24px 50px rgba(0,0,0,.4), inset 0 1px 1px rgba(255,255,255,.12)",
          padding:(caseH-SH)/2 + "px " + (caseW-SW)/2 + "px", boxSizing:"border-box" }}>
          {/* screen */}
          <div style={{ width:SW, height:SH, borderRadius:42, overflow:"hidden", background:"var(--bg)",
            position:"relative", boxShadow:"inset 0 0 0 2px #000" }}>
            {children}
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { WatchFrame });

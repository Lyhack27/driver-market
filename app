import React, { useState, useRef, useEffect, Component } from "react";
import {
  Settings,
  ShoppingCart,
  Plus,
  Minus,
  Trash2,
  ChevronLeft,
  CheckCircle,
  Zap,
  Lock,
  Upload,
  X,
  CreditCard,
  AlertTriangle,
  Wifi
} from "lucide-react";

// ==========================
// 1. ESTILOS & ANIMACIONES
// ==========================
const styles = `
  @keyframes ping-slow {
    75%, 100% { transform: scale(2); opacity: 0; }
  }
  .animate-signal {
    animation: ping-slow 1.5s cubic-bezier(0, 0, 0.2, 1) infinite;
  }
  @keyframes pop-in {
    0% { transform: scale(0.8); opacity: 0; }
    100% { transform: scale(1); opacity: 1; }
  }
  .animate-pop {
    animation: pop-in 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
  }
`;

// ==========================
// 2. ERROR BOUNDARY
// ==========================
class ErrorBoundary extends Component {
  constructor(props) { super(props); this.state = { hasError: false }; }
  static getDerivedStateFromError() { return { hasError: true }; }
  reset = () => { localStorage.clear(); window.location.reload(); };
  render() {
    if (this.state.hasError) {
      return (
        <div className="fixed inset-0 flex flex-col items-center justify-center bg-[#0f1115] text-white p-8 text-center z-[9999]">
          <AlertTriangle size={64} className="text-red-500 mb-6" />
          <h1 className="text-2xl font-bold mb-2">System Error</h1>
          <button onClick={this.reset} className="bg-red-600 px-8 py-4 rounded-xl font-bold mt-6">REBOOT SYSTEM</button>
        </div>
      );
    }
    return this.props.children;
  }
}

// ==========================
// 3. UTILITIES
// ==========================
const loadData = (key, fallback) => {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch { return fallback; }
};

const saveData = (key, value) => {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch (e) { alert("Memory Full"); }
};

const compressImage = (file) => {
  return new Promise((resolve, reject) => {
    if (!file) return reject("No file");
    if (file.size > 8 * 1024 * 1024) return reject("Too large (>8MB)");
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = (e) => {
      const img = new Image();
      img.src = e.target.result;
      img.onload = () => {
        const canvas = document.createElement("canvas");
        const MAX_W = 300; const MAX_H = 200;
        let w = img.width; let h = img.height;
        if (w > h) { if (w > MAX_W) { h *= MAX_W / w; w = MAX_W; } } else { if (h > MAX_H) { w *= MAX_H / h; h = MAX_H; } }
        canvas.width = w; canvas.height = h;
        const ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0, w, h);
        resolve(canvas.toDataURL("image/jpeg", 0.6));
      };
    };
    reader.onerror = reject;
  });
};

// ==========================
// 4. UI COMPONENTS
// ==========================

const ProductCard = ({ item, qty, onAdd }) => (
  <button onClick={onAdd} className="bg-[#1a1f27] border border-white/5 rounded-2xl p-4 flex flex-col gap-3 active:scale-[.98] transition-all shadow-lg relative group overflow-hidden text-left h-full">
    {qty > 0 && <div className="absolute top-3 right-3 bg-blue-600 text-white w-6 h-6 rounded-full flex items-center justify-center font-bold text-xs shadow-lg z-10">{qty}</div>}
    {item.image ? (
      <div className="w-full h-32 rounded-xl overflow-hidden bg-white/5 border border-white/10 shadow-inner relative">
        <img src={item.image} className="w-full h-full object-contain p-2" alt={item.name} />
      </div>
    ) : (
      <div className="w-full h-32 rounded-xl overflow-hidden bg-black/30 border border-white/10 flex items-center justify-center"><Zap className="text-gray-600" size={32}/></div>
    )}
    <div className="flex flex-col items-start w-full flex-1"><p className="text-white font-semibold text-lg line-clamp-1">{item.name}</p><p className="text-gray-400 text-sm font-mono">${item.price.toFixed(2)}</p></div>
    <div className="text-center text-sm text-white bg-blue-600 hover:bg-blue-500 w-full py-3 rounded-xl font-bold mt-auto">Add to Cart</div>
  </button>
);

const PinPad = ({ onCancel, onComplete, title }) => {
  const [pin, setPin] = useState("");
  const press = (n) => {
    if (n === "del") setPin((p) => p.slice(0, -1));
    else if (n === "clear") setPin("");
    else if (pin.length < 4) {
      const np = pin + n;
      setPin(np);
      if (np.length === 4) setTimeout(() => onComplete(np), 250);
    }
  };

  const overlayStyle = {
    position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh',
    backgroundColor: 'rgba(0,0,0,0.9)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 99999
  };

  return (
    <div style={overlayStyle}>
      <div className="w-full max-w-sm bg-[#181c22] border border-white/10 rounded-[2rem] p-8 shadow-2xl relative animate-pop">
        <button onClick={onCancel} className="absolute top-6 right-6 text-gray-400 hover:text-white"><X size={24} /></button>
        <div className="flex flex-col items-center">
          <Lock size={48} className="text-blue-500 mb-6" />
          <h2 className="text-2xl font-bold text-white mb-8 tracking-wide">{title || "Security PIN"}</h2>
          <div className="flex gap-4 mb-10">{[0, 1, 2, 3].map((i) => <div key={i} className={`w-4 h-4 rounded-full transition-all ${i < pin.length ? 'bg-blue-500 scale-110' : 'bg-gray-700'}`} />)}</div>
          <div className="grid grid-cols-3 gap-4 w-full">
            {[1,2,3,4,5,6,7,8,9].map((n) => (
              <button key={n} onClick={() => press(n)} className="h-20 rounded-2xl bg-[#0f1115] border border-white/5 text-2xl text-white active:scale-90 font-medium">{n}</button>
            ))}
            <div className="h-20"></div>
            <button onClick={() => press(0)} className="h-20 rounded-2xl bg-[#0f1115] border border-white/5 text-2xl text-white active:scale-90 font-medium">0</button>
            <button onClick={() => press('del')} className="h-20 rounded-2xl bg-red-900/20 border border-white/5 text-red-500 flex items-center justify-center active:scale-90"><ChevronLeft size={28} /></button>
          </div>
        </div>
      </div>
    </div>
  );
};

// --- SEÑAL DE PAGO CON BOTÓN CANCELAR ---
const PaymentSignal = ({ onCancel }) => (
  <div className="fixed top-0 right-0 w-full md:w-1/2 h-full bg-[#0f1115]/95 backdrop-blur-xl z-[9999] flex flex-col items-center justify-center border-l border-emerald-500/30">
    <div className="relative flex items-center justify-center">
      <div className="absolute w-64 h-64 bg-emerald-500/20 rounded-full animate-signal"></div>
      <div className="absolute w-48 h-48 bg-emerald-500/30 rounded-full animate-signal" style={{animationDelay: '0.2s'}}></div>
      <div className="w-32 h-32 bg-[#1a1f27] rounded-full border-4 border-emerald-500 flex items-center justify-center shadow-[0_0_30px_rgba(16,185,129,0.5)] z-10">
         <Wifi size={64} className="text-emerald-400" />
      </div>
    </div>
    <h2 className="text-3xl font-bold text-white mt-12 tracking-tight">Connecting to Square...</h2>
    <p className="text-emerald-400 mt-4 font-medium animate-pulse mb-10">Please follow instructions on terminal</p>
    
    {/* BOTÓN CANCELAR OPERACIÓN */}
    <button 
      onClick={onCancel}
      className="px-6 py-3 rounded-xl border border-red-500/30 text-red-400 font-bold hover:bg-red-900/20 hover:text-red-300 transition-all text-sm active:scale-95 flex items-center gap-2"
    >
      <X size={18} /> Cancel Operation
    </button>
  </div>
);

// --- PANTALLA DE ÉXITO ---
const SuccessScreen = ({ onClose }) => (
  <div className="fixed inset-0 bg-[#0f1115] z-[10000] flex flex-col items-center justify-center p-8 animate-pop">
    <div className="w-32 h-32 bg-emerald-500 rounded-full flex items-center justify-center mb-8 shadow-[0_0_50px_rgba(16,185,129,0.5)]">
       <CheckCircle size={64} className="text-[#0f1115]" />
    </div>
    <h1 className="text-4xl font-bold text-white mb-4">Payment Successful</h1>
    <p className="text-gray-400 text-lg mb-12">Thank you for your purchase!</p>
    <button onClick={onClose} className="bg-emerald-600 px-12 py-4 rounded-2xl text-xl font-bold text-white shadow-lg hover:bg-emerald-500 transition-all active:scale-95">
      New Order
    </button>
  </div>
);

// ==========================
// 5. MAIN APP LOGIC
// ==========================
const KioskApp = () => {
  const [config, setConfig] = useState(null);
  const [products, setProducts] = useState([]);
  const [cart, setCart] = useState([]);
  const [view, setView] = useState("loading");
  const [showPin, setShowPin] = useState(false);
  const [showAdmin, setShowAdmin] = useState(false);
  const [filter, setFilter] = useState("all");
  
  const [pendingAction, setPendingAction] = useState(null); 
  const [targetId, setTargetId] = useState(null);
  
  const [isPaying, setIsPaying] = useState(false);
  const [paymentSuccess, setPaymentSuccess] = useState(false);

  const [newItem, setNewItem] = useState({ name: "", price: "", category: "drinks", image: null });
  const fileRef = useRef(null);

  useEffect(() => {
    const cfg = loadData("kiosk_cfg", null);
    const prd = loadData("kiosk_products", []);
    
    const savedCart = loadData("kiosk_pending_cart", []);
    if (savedCart.length > 0) setCart(savedCart);

    const initialProducts = prd.length > 0 ? prd : [
      { id: 1, name: "Monster Energy", price: 3.50, category: "drinks", image: null },
      { id: 2, name: "Protein Bar", price: 2.50, category: "snacks", image: null },
    ];

    const urlParams = new URLSearchParams(window.location.search);
    const squareData = urlParams.get('data'); 

    if (squareData) {
      try {
        const response = JSON.parse(squareData);
        if (response.status === 'ok' || (response.error_code === undefined && response.status !== 'error')) {
          setPaymentSuccess(true); 
          saveData("kiosk_pending_cart", []); 
          setCart([]); 
        }
        window.history.replaceState({}, document.title, window.location.pathname);
      } catch (e) {
        console.error("Error parsing Square response", e);
      }
    }

    if (!cfg) { setView("setup"); } 
    else { setConfig(cfg); setProducts(initialProducts); setView("menu"); }
  }, []);

  const addToCart = (p) => setCart((old) => {
    const exist = old.find((x) => x.id === p.id);
    if (!exist) return [...old, { ...p, quantity: 1 }];
    return old.map((x) => (x.id === p.id ? { ...x, quantity: x.quantity + 1 } : x));
  });

  const updateQty = (id, delta) => setCart((old) => old.map((x) => (x.id === id ? { ...x, quantity: x.quantity + delta } : x)).filter((x) => x.quantity > 0));

  const handlePay = () => {
    if (cart.length === 0) return;
    
    saveData("kiosk_pending_cart", cart);
    setIsPaying(true); 

    setTimeout(() => {
      const totalCents = Math.round(cart.reduce((a, b) => a + b.price * b.quantity, 0) * 100);
      const callbackUrl = window.location.href; 

      const squareUrl = `square-commerce-v1://payment/create?data=${encodeURIComponent(JSON.stringify({
        amount_money: { amount: totalCents, currency_code: "USD" },
        callback_url: callbackUrl, 
        client_id: config?.squareAppId || "test",
        version: "1.3",
        notes: "Order Payment",
        options: { supported_tender_types: ["CREDIT_CARD","CONTACTLESS","CASH"] }
      }))}`;
      
      window.location.href = squareUrl;
    }, 1500);
  };

  const executeProtectedAction = () => {
    if (pendingAction === 'add') {
        if (!newItem.name.trim() || !newItem.price) return alert("Invalid Input");
        const prd = [...products, { ...newItem, id: Date.now(), price: parseFloat(newItem.price) }];
        setProducts(prd);
        saveData("kiosk_products", prd);
        setNewItem({ name: "", price: "", category: "drinks", image: null });
        if (fileRef.current) fileRef.current.value = "";
    } else if (pendingAction === 'delete' && targetId) {
        const next = products.filter(i => i.id !== targetId);
        setProducts(next);
        saveData("kiosk_products", next);
    } else if (pendingAction === 'upload_image') {
        if (fileRef.current) fileRef.current.click();
    }
    setPendingAction(null); setTargetId(null); setShowPin(false);
  };

  const requestAdd = () => {
      if (!newItem.name.trim() || !newItem.price) return alert("Missing Data");
      setPendingAction('add'); setShowPin(true);
  };

  const requestDelete = (id) => {
      setTargetId(id); setPendingAction('delete'); setShowPin(true);
  };

  const requestUploadImage = () => {
      setPendingAction('upload_image'); setShowPin(true);
  };

  const handleImage = async (e) => {
    if (!e.target.files[0]) return;
    try {
      const img = await compressImage(e.target.files[0]);
      setNewItem((p) => ({ ...p, image: img }));
    } catch (err) { alert(err); }
  };

  const finishSetup = (e) => {
    e.preventDefault();
    const f = new FormData(e.target);
    const pin = f.get("pin");
    const conf = f.get("confirm");
    const squareId = f.get("squareId");
    if (pin.length !== 4 || pin !== conf) return alert("Check PIN");
    if (!squareId) return alert("Square ID required");
    const cfg = { pin, squareAppId: squareId };
    saveData("kiosk_cfg", cfg); setConfig(cfg); setView("menu");
  };

  const total = cart.reduce((a, b) => a + b.price * b.quantity, 0);

  if (view === "loading") return <div className="h-screen flex items-center justify-center bg-[#0f1115] text-white">Loading System...</div>;

  if (view === "setup") return (
    <div className="min-h-screen w-full flex items-center justify-center bg-[#0f1115] px-4">
      <form onSubmit={finishSetup} className="w-full max-w-md bg-[#1a1f27] border border-white/5 rounded-3xl p-8 text-white shadow-xl">
        <h1 className="text-3xl font-bold mb-2 text-center">Setup</h1>
        <p className="text-gray-400 mb-8 text-center">System Configuration</p>
        <input name="squareId" className="w-full bg-[#0f1115] border border-white/10 p-4 rounded-xl mb-6 text-white outline-none focus:border-blue-500 transition-colors" placeholder="Square App ID (sq0idp-...)" required />
        <div className="flex gap-4 mb-8">
            <input name="pin" type="tel" maxLength={4} className="w-1/2 bg-[#0f1115] border border-white/10 p-4 rounded-xl text-center text-xl tracking-widest text-white outline-none focus:border-blue-500" placeholder="PIN" required />
            <input name="confirm" type="tel" maxLength={4} className="w-1/2 bg-[#0f1115] border border-white/10 p-4 rounded-xl text-center text-xl tracking-widest text-white outline-none focus:border-blue-500" placeholder="Confirm" required />
        </div>
        <button className="w-full bg-blue-600 py-4 rounded-xl font-bold active:scale-95 text-lg">Save & Launch</button>
      </form>
    </div>
  );

  return (
    <div className="flex h-screen bg-[#0f1115] text-white overflow-hidden font-sans relative">
      <style>{styles}</style>
      
      {/* PASAMOS LA FUNCION DE CANCELAR AL COMPONENTE */}
      {isPaying && <PaymentSignal onCancel={() => setIsPaying(false)} />}
      
      {paymentSuccess && <SuccessScreen onClose={() => setPaymentSuccess(false)} />}

      {showPin && <PinPad title={pendingAction === 'add' ? "Authorize Add" : pendingAction === 'upload_image' ? "Authorize Upload" : "Authorize Delete"} onCancel={() => { setShowPin(false); setPendingAction(null); }} onComplete={(p) => { if (p === config.pin) executeProtectedAction(); else alert("Incorrect PIN"); }} />}

      {showAdmin && (
        <div className="fixed inset-0 bg-[#0f1115] z-40 overflow-y-auto p-6">
          <div className="max-w-4xl mx-auto">
            <div className="flex justify-between items-center mb-8">
              <h2 className="text-2xl font-bold flex items-center gap-2"><Settings className="text-blue-500"/> Admin Panel</h2>
              <button onClick={() => setShowAdmin(false)} className="px-6 py-2 bg-[#1a1f27] rounded-xl border border-white/10">Exit</button>
            </div>
            <div className="bg-[#1a1f27] border border-white/5 rounded-2xl p-6 mb-8">
              <h3 className="text-lg font-bold mb-4">Add Product</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <input className="bg-[#0f1115] border border-white/5 p-4 rounded-xl outline-none focus:border-blue-500" placeholder="Name" value={newItem.name} onChange={(e) => setNewItem({ ...newItem, name: e.target.value })} />
                <input className="bg-[#0f1115] border border-white/5 p-4 rounded-xl outline-none focus:border-blue-500" type="number" placeholder="Price" value={newItem.price} onChange={(e) => setNewItem({ ...newItem, price: e.target.value })} />
                <select className="bg-[#0f1115] border border-white/5 p-4 rounded-xl outline-none" value={newItem.category} onChange={(e) => setNewItem({ ...newItem, category: e.target.value })}><option value="drinks">Drinks</option><option value="snacks">Snacks</option><option value="essentials">Essentials</option></select>
              </div>
              <div className="flex gap-4">
                 <button onClick={requestUploadImage} className="flex-1 py-4 rounded-xl border border-dashed border-white/10 flex items-center justify-center gap-2 text-gray-400 hover:text-white hover:border-blue-500 transition-all"><Upload size={20} /> {newItem.image ? "Image Ready" : "Upload Image"}</button>
                 <input type="file" hidden ref={fileRef} onChange={handleImage} />
                 <button onClick={requestAdd} className="px-8 bg-blue-600 rounded-xl font-bold flex items-center gap-2"><Lock size={16}/> Save</button>
              </div>
            </div>
            <div className="space-y-3 pb-20">
               {products.map(p => (
                 <div key={p.id} className="bg-[#1a1f27] border border-white/5 rounded-xl p-4 flex justify-between items-center">
                    <div className="flex items-center gap-4">
                       {p.image ? <img src={p.image} className="w-16 h-16 object-contain bg-black/20 p-1 rounded-lg"/> : <div className="w-16 h-12 bg-black/30 rounded-lg flex items-center justify-center"><Zap size={20} className="text-gray-600"/></div>}
                       <div><p className="font-bold">{p.name}</p><p className="text-sm text-gray-400">${p.price.toFixed(2)}</p></div>
                    </div>
                    <button onClick={() => requestDelete(p.id)} className="text-red-500 p-2 hover:bg-red-900/20 rounded-lg"><Trash2 size={20}/></button>
                 </div>
               ))}
            </div>
            <button onClick={()=>{if(confirm('Delete everything?')){localStorage.clear(); window.location.reload()}}} className="w-full py-4 mt-8 border border-red-900/50 text-red-500 font-bold rounded-xl hover:bg-red-900/10">Factory Reset</button>
          </div>
        </div>
      )}

      <div className="flex-1 flex flex-col overflow-hidden relative">
        <header className="h-20 bg-[#0f1115]/90 backdrop-blur border-b border-white/5 flex items-center justify-between px-8 shrink-0 z-10">
          <h1 className="text-2xl font-bold tracking-tight">Ride Market</h1>
          <button onClick={() => setShowAdmin(true)} className="p-3 bg-[#1a1f27] rounded-full text-gray-400 hover:text-white hover:bg-[#252b36] transition-all"><Settings size={20}/></button>
        </header>
        <div className="p-6 shrink-0">
          <div className="flex gap-3 overflow-x-auto pb-2">
            {["all", "drinks", "snacks", "essentials"].map((c) => (
              <button key={c} onClick={() => setFilter(c)} className={`px-6 py-2 rounded-full text-sm font-bold border transition-all capitalize ${filter === c ? "bg-blue-600 border-blue-500 text-white" : "bg-[#1a1f27] border-white/5 text-gray-400"}`}>{c}</button>
            ))}
          </div>
        </div>
        <div className="flex-1 overflow-y-auto p-6 pt-0 pb-32">
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-5">
            {products.filter(p => filter === "all" || p.category === filter).map(p => (
              <ProductCard key={p.id} item={p} qty={cart.find(i=>i.id===p.id)?.quantity||0} onAdd={()=>addToCart(p)} />
            ))}
          </div>
        </div>
      </div>

      <aside className="w-80 bg-[#1a1f27] border-l border-white/5 flex flex-col shadow-2xl z-30 shrink-0">
        <div className="h-20 border-b border-white/5 flex items-center px-6 shrink-0 bg-[#1a1f27]">
          <h2 className="text-xl font-bold flex items-center gap-2"><ShoppingCart className="text-blue-500" size={22} /> Current Order</h2>
        </div>
        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {cart.length === 0 && <div className="text-center text-gray-600 mt-20">Cart is empty</div>}
          {cart.map((i) => (
            <div key={i.id} className="bg-[#0f1115] border border-white/5 rounded-xl p-3 flex items-center justify-between">
              <div><p className="font-bold text-sm text-white">{i.name}</p><p className="text-blue-400 text-xs font-mono">${(i.price * i.quantity).toFixed(2)}</p></div>
              <div className="flex items-center gap-2">
                <button onClick={() => updateQty(i.id, -1)} className="w-8 h-8 rounded-lg bg-[#1a1f27] text-gray-400 flex items-center justify-center hover:text-white"><Minus size={16} /></button>
                <span className="w-4 text-center font-bold text-sm">{i.quantity}</span>
                <button onClick={() => updateQty(i.id, 1)} className="w-8 h-8 rounded-lg bg-blue-600 text-white flex items-center justify-center hover:bg-blue-500"><Plus size={16} /></button>
              </div>
            </div>
          ))}
        </div>
        <div className="p-6 bg-[#161920] border-t border-white/5 shrink-0 space-y-4">
          <div className="space-y-2">
            <div className="flex justify-between text-gray-400 text-sm"><span>Subtotal</span><span>${total.toFixed(2)}</span></div>
            <div className="flex justify-between text-gray-400 text-sm"><span>Tax (0%)</span><span>$0.00</span></div>
            <div className="h-px bg-white/10 my-2"></div>
            <div className="flex justify-between text-xl font-bold text-white"><span>Total</span><span>${total.toFixed(2)}</span></div>
          </div>
          <button 
            onClick={handlePay} 
            disabled={cart.length === 0 || isPaying} 
            className={`w-full py-4 rounded-xl font-bold text-lg transition-all active:scale-95 shadow-lg flex items-center justify-center gap-2 ${cart.length === 0 ? "bg-[#252b36] text-gray-600 cursor-not-allowed" : "bg-blue-600 hover:bg-blue-500 text-white shadow-blue-900/20"}`}
          >
             {isPaying ? "Connecting..." : "Pay with Square"} {isPaying ? <Zap className="animate-pulse" size={20} /> : <ChevronLeft className="rotate-180" size={20} />}
          </button>
          <div className="flex justify-center gap-3 opacity-50 pt-1"><CreditCard size={16} className="text-gray-400" /><Zap size={16} className="text-gray-400" /><span className="text-xs text-gray-500">Card & Contactless</span></div>
        </div>
      </aside>
    </div>
  );
};

export default function AppWrapper() { return <ErrorBoundary><KioskApp /></ErrorBoundary>; }

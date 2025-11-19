import React, { useState, useRef, useEffect, Component } from 'react';
import { ShoppingCart, Plus, Minus, Trash2, ChevronLeft, CheckCircle, Zap, Cookie, Smile, Sparkles, Wind, Settings, X, Upload, Lock, Image as ImageIcon, LayoutGrid, List } from 'lucide-react';

// ==============================================
// 1. SAFETY SYSTEM
// ==============================================
class ErrorBoundary extends Component {
  constructor(props) { super(props); this.state = { hasError: false }; }
  static getDerivedStateFromError(error) { return { hasError: true }; }
  handleReset = () => { localStorage.clear(); window.location.reload(); };
  render() {
    if (this.state.hasError) {
      return (
        <div className="fixed inset-0 bg-slate-950 text-white flex flex-col items-center justify-center z-[9999] p-8 text-center">
          <div className="bg-red-500/10 p-6 rounded-full mb-6">
             <Zap size={64} className="text-red-500" />
          </div>
          <h1 className="text-2xl font-bold mb-2">Something went wrong</h1>
          <p className="text-slate-400 mb-8">System encountered an unexpected error.</p>
          <button onClick={this.handleReset} className="bg-red-600 px-8 py-4 rounded-xl font-bold shadow-lg active:scale-95 transition-transform">
            SYSTEM RESET
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

// ==============================================
// 2. UTILITIES
// ==============================================
const DEFAULT_PRODUCTS = [
  { id: 1, name: "Monster Energy", price: 3.50, category: "drinks", color: "bg-slate-800", iconType: "zap", image: null },
  { id: 2, name: "Protein Bar", price: 2.50, category: "snacks", color: "bg-slate-800", iconType: "cookie", image: null },
];

const getIcon = (type, className) => {
  const icons = { zap: Zap, cookie: Cookie, smile: Smile, sparkles: Sparkles, wind: Wind };
  const Icon = icons[type] || Zap;
  return <Icon className={className} />;
};

const safeLoad = (key, fallback) => {
  try {
    const item = localStorage.getItem(key);
    return item ? JSON.parse(item) : fallback;
  } catch { return fallback; }
};

const compressImage = (file) => {
  return new Promise((resolve, reject) => {
    if (file.size > 5 * 1024 * 1024) { reject(new Error("Image too large (>5MB).")); return; }
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = (e) => {
      const img = new Image();
      img.src = e.target.result;
      img.onload = () => {
        const canvas = document.createElement('canvas');
        const MAX = 300; 
        let w = img.width, h = img.height;
        if (w > h) { if (w > MAX) { h *= MAX / w; w = MAX; } } 
        else { if (h > MAX) { w *= MAX / h; h = MAX; } }
        canvas.width = w; canvas.height = h;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, w, h);
        resolve(canvas.toDataURL('image/jpeg', 0.7));
      };
    };
    reader.onerror = reject;
  });
};

// ==============================================
// 3. COMPONENTS
// ==============================================

// Payment Buttons (Visual)
const PaymentMethodButton = ({ type, active }) => (
  <div className={`h-16 w-full rounded-xl flex items-center justify-center gap-2 border transition-all duration-200 cursor-pointer ${active ? 'border-blue-500 bg-blue-500/10 shadow-[0_0_20px_rgba(59,130,246,0.3)]' : 'bg-slate-800 border-slate-700 text-slate-400 opacity-60 grayscale hover:grayscale-0 hover:opacity-100'}`}>
    {type === 'card' ? (
       <div className="flex flex-col items-center">
          <div className="font-bold text-white text-sm">Credit Card</div>
          <div className="text-[10px] text-slate-400">Visa / MC / Amex</div>
       </div>
    ) : (
       <div className="flex items-center gap-2">
         <span className="font-bold text-white text-lg tracking-tight">Pay</span>
         <span className="bg-white text-black text-xs font-bold px-1.5 py-0.5 rounded">App</span>
       </div>
    )}
  </div>
);

// Product Card
const ProductCard = ({ product, cartQuantity, onAdd }) => (
  <button 
    onClick={onAdd}
    className="relative flex flex-col p-0 bg-slate-900 border border-slate-800 rounded-3xl shadow-lg active:scale-[0.98] transition-all duration-200 outline-none group hover:border-blue-500/50 hover:shadow-blue-900/20 w-full h-64 overflow-hidden text-left"
  >
    {cartQuantity > 0 && (
      <div className="absolute top-3 right-3 bg-blue-600 text-white w-8 h-8 rounded-full flex items-center justify-center font-bold shadow-lg animate-in zoom-in duration-200 z-10 border-2 border-slate-900">
        {cartQuantity}
      </div>
    )}
    
    {/* Rectangle Image */}
    <div className="w-full h-36 bg-slate-950 flex items-center justify-center overflow-hidden relative">
      {product.image ? (
        <img src={product.image} alt={product.name} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" />
      ) : (
        <div className="w-full h-full flex items-center justify-center bg-slate-800/50">
           {getIcon(product.iconType, "w-12 h-12 text-slate-600 group-hover:text-blue-400 transition-colors")}
        </div>
      )}
      <div className="absolute inset-0 bg-gradient-to-t from-slate-900 via-transparent to-transparent opacity-80"></div>
    </div>

    <div className="p-4 flex flex-col justify-between flex-1 w-full relative z-0">
      <div>
        <h3 className="text-base font-bold text-white leading-tight mb-1 line-clamp-2">{product.name}</h3>
        <p className="text-blue-400 font-bold text-lg">${parseFloat(product.price).toFixed(2)}</p>
      </div>
      <div className="mt-2 w-full py-1.5 bg-slate-800 text-slate-300 rounded-lg text-xs font-bold uppercase tracking-wider text-center group-hover:bg-blue-600 group-hover:text-white transition-colors">
        Add to Order
      </div>
    </div>
  </button>
);

// PIN Pad Modal (Admin Access)
const PinPad = ({ onComplete, onCancel }) => {
  const [pin, setPin] = useState("");
  
  const handlePress = (n) => {
    if (n === "del") setPin(p => p.slice(0, -1));
    else if (n === "clear") setPin("");
    else if (pin.length < 4) {
      const newP = pin + n;
      setPin(newP);
      if (newP.length === 4) setTimeout(() => onComplete(newP), 300);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-950/95 backdrop-blur-md z-[9999] flex items-center justify-center p-4 animate-in fade-in duration-200">
      <div className="w-full max-w-[340px] bg-slate-900 border border-slate-800 rounded-[2rem] p-6 shadow-2xl flex flex-col items-center relative">
        <button onClick={onCancel} className="absolute top-4 right-4 text-slate-500 hover:text-white"><X size={24}/></button>
        
        <Lock size={32} className="text-blue-500 mb-4" />
        <h2 className="text-xl font-bold text-white mb-6">Enter Admin PIN</h2>
        
        <div className="flex gap-4 mb-8 h-4">
          {[0, 1, 2, 3].map(i => (
            <div key={i} className={`w-3 h-3 rounded-full transition-all duration-200 ${i < pin.length ? 'bg-blue-500 scale-125 shadow-[0_0_10px_#3b82f6]' : 'bg-slate-800'}`} />
          ))}
        </div>

        <div className="grid grid-cols-3 gap-3 w-full mb-2">
          {[1,2,3,4,5,6,7,8,9].map((n) => (
            <button key={n} onClick={() => handlePress(n)} className="h-16 w-full rounded-2xl bg-slate-800 text-2xl font-medium text-white hover:bg-slate-700 active:scale-95 transition-all border border-slate-700/50">
              {n}
            </button>
          ))}
          <button onClick={() => handlePress("clear")} className="h-16 w-full rounded-2xl bg-slate-800/50 text-lg font-medium text-slate-400 hover:bg-slate-800 active:scale-95 transition-all flex items-center justify-center">C</button>
          <button onClick={() => handlePress(0)} className="h-16 w-full rounded-2xl bg-slate-800 text-2xl font-medium text-white hover:bg-slate-700 active:scale-95 transition-all border border-slate-700/50">0</button>
          <button onClick={() => handlePress("del")} className="h-16 w-full rounded-2xl bg-slate-800/50 text-red-400 hover:bg-red-900/20 active:scale-95 transition-all flex items-center justify-center"><ChevronLeft size={28}/></button>
        </div>
      </div>
    </div>
  );
};

// ==============================================
// 4. MAIN APPLICATION
// ==============================================
const KioscoApp = () => {
  const [status, setStatus] = useState('loading'); 
  const [products, setProducts] = useState([]);
  const [config, setConfig] = useState(null);
  const [cart, setCart] = useState([]);
  
  // UI State
  const [showPinPad, setShowPinPad] = useState(false);
  const [showAdmin, setShowAdmin] = useState(false);
  const [showPayment, setShowPayment] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [filter, setFilter] = useState('all');
  const [adminMsg, setAdminMsg] = useState(''); // Visual feedback

  // Admin Form State
  const [newProduct, setNewProduct] = useState({ name: '', price: '', category: 'drinks', image: null });
  const fileInputRef = useRef(null);

  // INITIALIZATION
  useEffect(() => {
    const savedConfig = safeLoad('kiosco_config', null);
    const savedProducts = safeLoad('kiosco_products', DEFAULT_PRODUCTS);

    if (savedConfig && savedConfig.pin) {
      setConfig(savedConfig);
      setProducts(savedProducts);
      setStatus('menu');
    } else {
      setStatus('setup');
    }
  }, []);

  // --- LOGIC ---

  const finishSetup = (data) => {
    setConfig(data);
    setProducts(DEFAULT_PRODUCTS);
    localStorage.setItem('kiosco_config', JSON.stringify(data));
    localStorage.setItem('kiosco_products', JSON.stringify(DEFAULT_PRODUCTS));
    setStatus('menu');
  };

  const saveProducts = (list) => {
    try {
      const str = JSON.stringify(list);
      if (str.length > 4500000) throw new Error("Quota");
      localStorage.setItem('kiosco_products', str);
      setProducts(list);
      return true;
    } catch (e) {
      alert("Storage full. Saving without image.");
      const cleanList = list.map(p => p.id === newProduct.id ? {...p, image: null} : p);
      setProducts(cleanList);
      localStorage.setItem('kiosco_products', JSON.stringify(cleanList));
      return false;
    }
  };

  const handleAddProduct = () => {
    const name = newProduct.name.trim();
    const price = parseFloat(newProduct.price);

    if (!name || isNaN(price)) {
      setAdminMsg("Error: Invalid Name or Price");
      setTimeout(() => setAdminMsg(""), 3000);
      return;
    }

    const newItem = { 
      ...newProduct, 
      name, 
      price: price, 
      id: Date.now(), 
      color: 'bg-slate-800', 
      iconType: 'zap' 
    };
    
    saveProducts([...products, newItem]);
    setNewProduct({ name: '', price: '', category: 'drinks', image: null });
    if (fileInputRef.current) fileInputRef.current.value = "";
    
    // Feedback message
    setAdminMsg("Product Added Successfully!");
    setTimeout(() => setAdminMsg(""), 3000);
  };

  const handleImage = async (e) => {
    if (e.target.files[0]) {
      try {
        const b64 = await compressImage(e.target.files[0]);
        setNewProduct(prev => ({ ...prev, image: b64 }));
      } catch (err) { alert(err.message); }
    }
  };

  const handlePay = () => {
    // 1. Calculate total
    const totalAmount = cart.reduce((sum, i) => sum + (parseFloat(i.price) * i.quantity), 0);
    
    if (totalAmount <= 0) return;

    setIsProcessing(true);

    // 2. Attempt Square Deep Link
    if (config?.squareAppId) {
        const params = {
          amount_money: { amount: Math.round(totalAmount * 100), currency_code: "USD" },
          callback_url: window.location.href,
          client_id: config.squareAppId,
          version: "1.3",
          notes: "Kiosco Order",
          options: { supported_tender_types: ["CREDIT_CARD", "CONTACTLESS", "CASH"] }
        };
        
        try {
             const url = `square-commerce-v1://payment/create?data=${encodeURIComponent(JSON.stringify(params))}`;
             // window.location.href = url; 
        } catch (e) {
            console.log("Could not open native app");
        }
    }

    // 3. Simulate Process
    setTimeout(() => { 
      setIsProcessing(false); 
      setShowPayment(false); 
      setShowSuccess(true); 
      setCart([]); 
      setTimeout(() => setShowSuccess(false), 3000); 
    }, 2500);
  };

  const updateCart = (p, delta) => {
    setCart(prev => {
      const exists = prev.find(i => i.id === p.id);
      if (!exists && delta > 0) return [...prev, { ...p, quantity: 1 }];
      return prev.map(i => i.id === p.id ? { ...i, quantity: Math.max(0, i.quantity + delta) } : i).filter(i => i.quantity > 0);
    });
  };

  const cartTotal = cart.reduce((a,b) => a + (parseFloat(b.price||0) * (b.quantity||0)), 0);

  // --- RENDER ---

  if (status === 'loading') return <div className="h-screen bg-slate-950 text-white flex items-center justify-center animate-pulse">System Loading...</div>;
  
  // SETUP SCREEN (Responsive Fix)
  if (status === 'setup') {
    return (
      <div className="fixed inset-0 bg-slate-950 flex items-center justify-center p-4 z-50 overflow-y-auto">
        <div className="w-11/12 max-w-md bg-slate-900 p-8 rounded-3xl border border-slate-800 shadow-2xl flex flex-col animate-in zoom-in duration-300 my-auto">
          <div className="text-center mb-8">
            <div className="w-20 h-20 bg-blue-600 rounded-2xl mx-auto mb-4 flex items-center justify-center shadow-lg shadow-blue-900/20">
                <Settings size={40} className="text-white" />
            </div>
            <h1 className="text-2xl font-bold text-white">Initial Setup</h1>
            <p className="text-slate-500 text-sm mt-2">Configure Kiosk for tablets</p>
          </div>
          <form onSubmit={(e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const pin = formData.get('pin');
            const confirm = formData.get('confirm');
            const squareId = formData.get('squareId');
            if (pin.length !== 4) return alert("PIN must be 4 digits");
            if (pin !== confirm) return alert("PINs do not match");
            finishSetup({ pin, squareAppId: squareId || "test" });
          }} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
                <input name="pin" type="tel" maxLength={4} className="bg-slate-950 border border-slate-700 p-4 rounded-xl text-white text-center text-xl outline-none focus:border-blue-500 transition-colors" placeholder="PIN" required />
                <input name="confirm" type="tel" maxLength={4} className="bg-slate-950 border border-slate-700 p-4 rounded-xl text-white text-center text-xl outline-none focus:border-blue-500 transition-colors" placeholder="Confirm" required />
            </div>
            <input name="squareId" type="text" className="w-full bg-slate-950 border border-slate-700 p-4 rounded-xl text-white outline-none focus:border-blue-500 transition-colors text-sm" placeholder="Square App ID (Optional)" />
            <button type="submit" className="w-full bg-blue-600 hover:bg-blue-500 text-white font-bold py-4 rounded-xl text-lg shadow-lg mt-4 active:scale-95 transition-transform">Save & Launch</button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-slate-950 text-white font-sans overflow-hidden selection:bg-blue-500/30">
      
      {/* MODAL: PIN PAD */}
      {showPinPad && (
        <PinPad 
            onComplete={(enteredPin) => {
                if(enteredPin === config.pin) {
                    setShowPinPad(false);
                    setShowAdmin(true);
                } else {
                    alert("Incorrect PIN"); 
                }
            }} 
            onCancel={() => setShowPinPad(false)} 
        />
      )}
      
      {/* MODAL: SUCCESS */}
      {showSuccess && (
        <div className="fixed inset-0 bg-emerald-600 z-[100] flex flex-col items-center justify-center animate-in zoom-in duration-300">
          <div className="bg-white rounded-full p-6 mb-6 shadow-2xl animate-bounce">
             <CheckCircle size={80} className="text-emerald-600" />
          </div>
          <h1 className="text-4xl md:text-6xl font-bold text-white text-center">Payment Successful!</h1>
          <p className="text-emerald-100 mt-4 text-xl">Thank you for your purchase</p>
        </div>
      )}

      {/* MODAL: PAYMENT & CHECKOUT */}
      {showPayment && (
        <div className="fixed inset-0 bg-slate-950/95 backdrop-blur-xl z-50 flex items-center justify-center p-4">
          <div className="w-full max-w-lg bg-slate-900 border border-slate-800 rounded-[2.5rem] p-8 text-center shadow-2xl relative overflow-hidden animate-in slide-in-from-bottom-10 duration-300">
            {isProcessing ? (
              <div className="py-20 flex flex-col items-center">
                <div className="relative w-24 h-24 mb-8">
                    <div className="absolute inset-0 border-4 border-slate-700 rounded-full"></div>
                    <div className="absolute inset-0 border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
                </div>
                <h2 className="text-3xl font-bold animate-pulse">Processing...</h2>
                <p className="text-slate-400 mt-4">Follow instructions on terminal</p>
              </div>
            ) : (
              <>
                <div className="flex justify-between items-center mb-8">
                     <button onClick={() => setShowPayment(false)} className="p-2 bg-slate-800 rounded-full text-slate-400 hover:text-white"><ChevronLeft size={24}/></button>
                     <h3 className="font-bold text-slate-400 uppercase tracking-widest text-sm">Checkout</h3>
                     <div className="w-10"></div>
                </div>
                
                <div className="mb-10">
                    <h2 className="text-6xl font-bold text-white mb-2 tracking-tight">${cartTotal.toFixed(2)}</h2>
                    <p className="text-slate-500 font-medium">Total to Pay</p>
                </div>
                
                <div className="grid grid-cols-2 gap-4 mb-8">
                  <PaymentMethodButton type="card" active={true} />
                  <PaymentMethodButton type="app" active={false} />
                </div>

                <button onClick={handlePay} className="w-full bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-500 hover:to-blue-400 text-white py-6 rounded-2xl text-2xl font-bold shadow-[0_10px_40px_-10px_rgba(37,99,235,0.5)] active:scale-95 flex items-center justify-center gap-3 transition-all">
                  <Zap fill="currentColor" className="animate-pulse"/> Pay Now
                </button>
              </>
            )}
          </div>
        </div>
      )}

      {/* MODAL: ADMIN PANEL */}
      {showAdmin && (
        <div className="fixed inset-0 bg-slate-950 z-50 flex flex-col animate-in slide-in-from-right duration-300">
          {/* Admin Header */}
          <div className="bg-slate-900 border-b border-slate-800 p-4 flex justify-between items-center shrink-0">
            <h1 className="text-xl font-bold text-white flex items-center gap-2"><Settings className="text-blue-500"/> Admin Panel</h1>
            <button onClick={() => setShowAdmin(false)} className="bg-slate-800 hover:bg-slate-700 px-6 py-2 rounded-xl font-bold text-sm transition-colors">Exit</button>
          </div>
          
          {/* Admin Content */}
          <div className="flex-1 overflow-y-auto p-4 md:p-8 max-w-5xl mx-auto w-full">
            
            {/* Add Product Form */}
            <div className="bg-slate-900 p-6 rounded-3xl border border-slate-800 mb-8 shadow-xl">
              <h3 className="text-lg font-bold mb-4 text-slate-300 flex items-center gap-2"><Plus size={18} /> Add Product</h3>
              
              <div className="flex flex-col md:flex-row gap-4 mb-4">
                <div className="flex-1 space-y-2">
                    <label className="text-xs text-slate-500 ml-2 uppercase font-bold">Name</label>
                    <input className="w-full bg-slate-950 p-4 rounded-xl border border-slate-700 outline-none focus:border-blue-500 transition-colors" placeholder="Ex. Coca Cola" value={newProduct.name} onChange={e=>setNewProduct({...newProduct, name:e.target.value})} />
                </div>
                <div className="w-full md:w-40 space-y-2">
                    <label className="text-xs text-slate-500 ml-2 uppercase font-bold">Price</label>
                    <input className="w-full bg-slate-950 p-4 rounded-xl border border-slate-700 outline-none focus:border-blue-500 transition-colors" type="number" placeholder="0.00" value={newProduct.price} onChange={e=>setNewProduct({...newProduct, price:e.target.value})} />
                </div>
                <div className="w-full md:w-48 space-y-2">
                    <label className="text-xs text-slate-500 ml-2 uppercase font-bold">Category</label>
                    <select className="w-full bg-slate-950 p-4 rounded-xl border border-slate-700 outline-none focus:border-blue-500" value={newProduct.category} onChange={e=>setNewProduct({...newProduct, category:e.target.value})}>
                        <option value="drinks">Drinks</option>
                        <option value="snacks">Snacks</option>
                        <option value="essentials">Essentials</option>
                    </select>
                </div>
              </div>

              <div className="flex flex-col md:flex-row gap-4 items-center">
                  <input type="file" hidden ref={fileInputRef} onChange={handleImage} accept="image/*" />
                  <button onClick={()=>fileInputRef.current.click()} className={`flex-1 w-full py-4 rounded-xl border border-dashed flex justify-center gap-3 items-center font-medium transition-colors ${newProduct.image ? 'border-green-500 bg-green-500/10 text-green-500' : 'border-slate-600 hover:border-slate-400 text-slate-400'}`}>
                    {newProduct.image ? <><ImageIcon size={20}/> Image Ready</> : <><Upload size={20}/> Upload Image</>}
                  </button>
                  
                  <button onClick={handleAddProduct} className="w-full md:w-auto px-8 py-4 bg-blue-600 rounded-xl font-bold hover:bg-blue-500 transition-colors shadow-lg shadow-blue-900/20 text-white">
                    Save Product
                  </button>
              </div>
              
              {/* Feedback Message */}
              {adminMsg && (
                 <div className={`mt-4 p-3 rounded-xl text-center font-bold animate-in fade-in slide-in-from-top-2 ${adminMsg.includes('Error') ? 'bg-red-500/20 text-red-400' : 'bg-emerald-500/20 text-emerald-400'}`}>
                    {adminMsg}
                 </div>
              )}
            </div>

            {/* Product List */}
            <div className="space-y-3 pb-20">
              <h3 className="text-lg font-bold mb-4 text-slate-300 flex items-center gap-2"><List size={18}/> Current Inventory</h3>
              {products.map(p => (
                <div key={p.id} className="flex justify-between items-center bg-slate-900 p-3 rounded-2xl border border-slate-800 hover:border-slate-700 transition-colors group">
                  <div className="flex items-center gap-4 overflow-hidden">
                    {/* Thumbnail visual fix */}
                    <div className="w-16 h-16 bg-slate-950 rounded-xl overflow-hidden border border-slate-800 shrink-0 relative">
                      {p.image ? (
                          <img src={p.image} className="w-full h-full object-cover" alt={p.name}/>
                      ) : (
                          <div className="w-full h-full flex items-center justify-center text-slate-700"><Zap size={20}/></div>
                      )}
                    </div>
                    
                    <div className="min-w-0">
                        <div className="font-bold text-white truncate text-lg">{p.name}</div>
                        <div className="text-slate-500 text-sm capitalize flex items-center gap-2">
                            <span className={`w-2 h-2 rounded-full ${p.category==='drinks' ? 'bg-blue-500': p.category==='snacks'?'bg-orange-500':'bg-purple-500'}`}></span>
                            {p.category}
                        </div>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-6 pl-4">
                    <span className="text-white font-mono font-bold text-lg">${parseFloat(p.price).toFixed(2)}</span>
                    <button onClick={() => { if(confirm("Delete this product?")) { const next = products.filter(x=>x.id!==p.id); saveProducts(next); } }} className="w-10 h-10 flex items-center justify-center text-slate-600 hover:text-red-500 hover:bg-red-500/10 rounded-xl transition-colors">
                        <Trash2 size={20}/>
                    </button>
                  </div>
                </div>
              ))}
              
              {products.length === 0 && (
                  <div className="text-center py-10 text-slate-600 italic">No products registered.</div>
              )}
            </div>
            
            <div className="mt-10 pt-10 border-t border-slate-800">
                <button onClick={()=>{if(confirm('Factory Reset app? All products will be deleted.')){localStorage.clear(); window.location.reload()}}} className="text-red-500 hover:text-red-400 text-sm font-bold py-2 px-4 hover:bg-red-900/10 rounded-lg transition-colors">
                    Factory Reset (Delete All)
                </button>
            </div>
          </div>
        </div>
      )}

      {/* --- MAIN LAYOUT --- */}
      
      {/* 1. LEFT CONTENT AREA (Catalog) */}
      <div className="flex-1 flex flex-col h-full relative bg-slate-950">
        <header className="h-20 bg-slate-900/90 backdrop-blur-md border-b border-slate-800 flex items-center justify-between px-6 shrink-0 z-10">
          <div>
              <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-white">Ride Market</h1>
          </div>
          <button onClick={() => setShowPinPad(true)} className="w-12 h-12 flex items-center justify-center rounded-full text-slate-500 hover:text-white hover:bg-slate-800 transition-colors">
              <Settings size={24} />
          </button>
        </header>

        {/* Categories */}
        <div className="p-6 overflow-x-auto shrink-0 no-scrollbar">
          <div className="flex gap-3 min-w-max">
            {['all', 'drinks', 'snacks', 'essentials'].map(cat => (
              <button key={cat} onClick={() => setFilter(cat)} className={`px-6 py-3 rounded-full text-sm font-bold capitalize border transition-all duration-200 ${filter === cat ? 'bg-blue-600 border-blue-500 text-white shadow-lg shadow-blue-900/20 scale-105' : 'bg-slate-900 border-slate-700 text-slate-400 hover:bg-slate-800 hover:text-white'}`}>
                {cat === 'all' ? 'All' : cat}
              </button>
            ))}
          </div>
        </div>

        {/* Product Grid */}
        <div className="flex-1 overflow-y-auto p-6 pt-0">
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6 pb-32">
            {products.filter(p => filter === 'all' || p.category === filter).map(p => (
              <ProductCard key={p.id} product={p} cartQuantity={cart.find(i => i.id === p.id)?.quantity || 0} onAdd={() => updateCart(p, 1)} />
            ))}
          </div>
        </div>
      </div>

      {/* 2. RIGHT SIDEBAR (Cart) */}
      <div className="w-80 md:w-96 bg-slate-900 border-l border-slate-800 flex flex-col shadow-2xl z-40 shrink-0 relative">
        <div className="h-20 border-b border-slate-800 flex items-center px-6 shrink-0 bg-slate-900/95 backdrop-blur">
            <h2 className="text-xl font-bold flex items-center gap-3 text-white"><ShoppingCart className="text-blue-500" size={24}/> Your Order</h2>
        </div>
        
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {cart.length === 0 && (
              <div className="flex flex-col items-center justify-center h-64 text-slate-600 gap-4">
                  <div className="w-20 h-20 bg-slate-800/50 rounded-full flex items-center justify-center">
                      <ShoppingCart size={32} className="opacity-50"/>
                  </div>
                  <p>Your cart is empty</p>
              </div>
          )}
          {cart.map(i => (
            <div key={i.id} className="bg-slate-950 p-3 pr-4 rounded-2xl border border-slate-800 flex justify-between items-center animate-in slide-in-from-right-4 duration-200">
              <div className="flex items-center gap-3">
                 {i.image ? <div className="w-10 h-10 rounded-lg overflow-hidden bg-slate-900"><img src={i.image} className="w-full h-full object-cover"/></div> : null}
                 <div>
                    <div className="font-bold text-sm text-white leading-tight">{i.name}</div>
                    <div className="text-blue-400 font-mono text-xs mt-0.5">${(i.price*i.quantity).toFixed(2)}</div>
                 </div>
              </div>
              <div className="flex items-center gap-3 bg-slate-900 rounded-xl p-1 border border-slate-800 shadow-sm">
                <button onClick={()=>updateCart(i, -1)} className="w-8 h-8 flex items-center justify-center rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"><Minus size={14}/></button>
                <span className="font-bold w-4 text-center text-sm">{i.quantity}</span>
                <button onClick={()=>updateCart(i, 1)} className="w-8 h-8 flex items-center justify-center rounded-lg text-blue-400 hover:text-white hover:bg-blue-600 transition-colors"><Plus size={14}/></button>
              </div>
            </div>
          ))}
        </div>

        <div className="p-6 bg-slate-900 border-t border-slate-800 shrink-0 shadow-[0_-10px_40px_-15px_rgba(0,0,0,0.5)]">
          <div className="flex justify-between text-xl font-bold mb-6 text-white">
              <span className="text-slate-400">Total</span>
              <span>${cartTotal.toFixed(2)}</span>
          </div>
          <button 
            onClick={() => { if(cart.length > 0) setShowPayment(true); }} 
            disabled={cart.length===0} 
            className={`w-full py-5 rounded-2xl font-bold text-xl shadow-lg transition-all duration-200 active:scale-[0.98] flex items-center justify-center gap-3 ${cart.length===0 ? 'bg-slate-800 text-slate-600 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-500 text-white shadow-blue-900/30'}`}
          >
            {cart.length === 0 ? 'Empty Cart' : 'Checkout'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default function AppWrapper() { return <ErrorBoundary><KioscoApp /></ErrorBoundary>; }

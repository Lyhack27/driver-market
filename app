import React, { useState, useRef } from 'react';
import { ShoppingCart, Plus, Minus, Trash2, ChevronLeft, Smartphone, CheckCircle, Zap, Cookie, Smile, Sparkles, Wind, CreditCard, ExternalLink, Settings, Save, X, Upload, Image as ImageIcon, Maximize, Minimize } from 'lucide-react';

// Datos Iniciales (Default) - Colores actualizados a tonos obscuros/tenues
const INITIAL_PRODUCTS = [
  { id: 1, name: "Monster Energy", price: 3.50, category: "drinks", color: "bg-emerald-900/40 text-emerald-300", iconType: "zap", image: null, imageFit: 'contain' },
  { id: 2, name: "Protein Bar", price: 2.50, category: "snacks", color: "bg-orange-900/40 text-orange-300", iconType: "cookie", image: null, imageFit: 'contain' },
  { id: 3, name: "Assorted Sweets", price: 2.00, category: "snacks", color: "bg-pink-900/40 text-pink-300", iconType: "smile", image: null, imageFit: 'contain' },
  { id: 4, name: "Cool Mints", price: 1.50, category: "snacks", color: "bg-cyan-900/40 text-cyan-300", iconType: "sparkles", image: null, imageFit: 'contain' },
  { id: 5, name: "Axe Spray (Men)", price: 5.00, category: "essentials", color: "bg-slate-700/50 text-slate-300", iconType: "wind", image: null, imageFit: 'contain' },
  { id: 6, name: "Axe Spray (Women)", price: 5.00, category: "essentials", color: "bg-purple-900/40 text-purple-300", iconType: "wind", image: null, imageFit: 'contain' },
];

// Helper para renderizar iconos dinámicamente
const getIcon = (type, className) => {
  switch(type) {
    case 'zap': return <Zap className={className} />;
    case 'cookie': return <Cookie className={className} />;
    case 'smile': return <Smile className={className} />;
    case 'sparkles': return <Sparkles className={className} />;
    case 'wind': return <Wind className={className} />;
    default: return <Zap className={className} />;
  }
};

// Componente de Tarjeta de Producto (Reutilizable para Preview y Menú)
const ProductCard = ({ product, cartQuantity, onAdd, isPreview = false }) => {
  return (
    <div 
      onClick={!isPreview ? onAdd : undefined}
      className={`bg-slate-900 rounded-2xl p-4 lg:p-6 shadow-lg border border-slate-800 transition-all flex flex-col items-center text-center h-56 lg:h-64 justify-between relative group ${
        !isPreview ? 'cursor-pointer hover:border-blue-500/50 hover:bg-slate-800 active:scale-95' : 'opacity-100 cursor-default pointer-events-none'
      }`}
    >
      {/* Quantity Badge (Solo en modo real) */}
      {!isPreview && cartQuantity > 0 && (
        <div className="absolute top-3 right-3 bg-blue-600 text-white w-8 h-8 rounded-full flex items-center justify-center font-bold shadow-lg shadow-blue-900/50 animate-bounce-short border border-blue-400">
          {cartQuantity}
        </div>
      )}
      
      {/* Contenedor de Imagen/Icono - Usamos el color definido en el producto */}
      <div className={`w-24 h-24 lg:w-28 lg:h-28 rounded-full flex items-center justify-center mb-2 overflow-hidden ${product.image ? 'bg-transparent' : product.color}`}>
        {product.image ? (
          <img 
            src={product.image} 
            alt={product.name} 
            className={`w-full h-full ${product.imageFit === 'cover' ? 'object-cover' : 'object-contain drop-shadow-lg'}`} 
          />
        ) : (
          // El color del icono se hereda del contenedor padre via product.color (text-color-300)
          getIcon(product.iconType, "w-10 h-10 lg:w-12 lg:h-12 opacity-90")
        )}
      </div>

      <div>
        <h3 className="font-bold text-lg lg:text-xl text-slate-100 leading-tight mb-1 line-clamp-2">
          {product.name || "Product Name"}
        </h3>
        <p className="text-slate-400 font-medium">
          ${product.price ? parseFloat(product.price).toFixed(2) : "0.00"}
        </p>
      </div>

      <button className={`mt-2 w-full py-2 bg-slate-800 text-blue-400 rounded-lg font-semibold text-sm lg:text-base transition-colors border border-slate-700 ${!isPreview ? 'group-hover:bg-blue-600 group-hover:text-white group-hover:border-blue-500' : ''}`}>
        Add to Order
      </button>
    </div>
  );
};

const KioscoApp = () => {
  // Estados
  const [products, setProducts] = useState(INITIAL_PRODUCTS);
  const [cart, setCart] = useState([]);
  const [view, setView] = useState('menu'); // menu, payment, success, admin
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [isProcessing, setIsProcessing] = useState(false);

  // Estado Admin
  const [newProduct, setNewProduct] = useState({ name: '', price: '', category: 'drinks', image: null, imageFit: 'contain' });
  const fileInputRef = useRef(null);

  // --- FUNCIONES DE ADMINISTRACIÓN ---
  
  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setNewProduct(prev => ({ ...prev, image: reader.result }));
      };
      reader.readAsDataURL(file);
    }
  };

  const handleAddProduct = () => {
    if (!newProduct.name || !newProduct.price) return;

    // Asignar colores tenues basados en la categoría
    let colorClass = "bg-slate-700/50 text-slate-300";
    if (newProduct.category === 'drinks') colorClass = "bg-blue-900/40 text-blue-300";
    if (newProduct.category === 'snacks') colorClass = "bg-orange-900/40 text-orange-300";
    if (newProduct.category === 'essentials') colorClass = "bg-purple-900/40 text-purple-300";

    const newItem = {
      id: Date.now(),
      name: newProduct.name,
      price: parseFloat(newProduct.price),
      category: newProduct.category,
      color: colorClass,
      iconType: 'zap', 
      image: newProduct.image, 
      imageFit: newProduct.imageFit
    };

    setProducts([...products, newItem]);
    setNewProduct({ name: '', price: '', category: 'drinks', image: null, imageFit: 'contain' });
    if (fileInputRef.current) fileInputRef.current.value = "";
  };

  const handleDeleteProduct = (id) => {
    setProducts(products.filter(p => p.id !== id));
  };

  // --- FUNCIONES DEL CARRITO ---
  const addToCart = (product) => {
    setCart(prev => {
      const existing = prev.find(item => item.id === product.id);
      if (existing) {
        return prev.map(item => 
          item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item
        );
      }
      return [...prev, { ...product, quantity: 1 }];
    });
  };

  const removeFromCart = (id) => {
    setCart(prev => prev.filter(item => item.id !== id));
  };

  const updateQuantity = (id, delta) => {
    setCart(prev => prev.map(item => {
      if (item.id === id) {
        const newQuantity = Math.max(0, item.quantity + delta);
        return { ...item, quantity: newQuantity };
      }
      return item;
    }).filter(item => item.quantity > 0));
  };

  const cartTotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);

  // --- LÓGICA DE PAGO ---
  const handleCheckout = () => {
    if (cart.length === 0) return;
    setView('payment');
  };

  const handleSquarePayment = () => {
    const amountCents = Math.round(cartTotal * 100);
    const currencyCode = "USD"; 
    
    const paymentParams = {
      amount_money: { amount: amountCents, currency_code: currencyCode },
      callback_url: "https://google.com", 
      client_id: "sq0idp-PLACEHOLDER-ID", 
      version: "1.3",
      notes: "Ride Market Order", 
      options: { supported_tender_types: ["CREDIT_CARD", "CONTACTLESS", "CASH", "OTHER"] }
    };

    const squareUrl = `square-commerce-v1://payment/create?data=${encodeURIComponent(JSON.stringify(paymentParams))}`;
    window.location.href = squareUrl;
    setIsProcessing(true);
    setTimeout(() => setIsProcessing(false), 3000);
  };

  const simulatePaymentSuccess = () => {
    setIsProcessing(true);
    setTimeout(() => {
      setIsProcessing(false);
      setView('success');
      setTimeout(() => {
        setCart([]);
        setView('menu');
      }, 5000);
    }, 2000);
  };

  // UI Components
  const CategoryButton = ({ id, label }) => (
    <button 
      onClick={() => setCategoryFilter(id)}
      className={`px-4 py-2 lg:px-6 lg:py-3 rounded-full text-sm lg:text-lg font-medium transition-all whitespace-nowrap border ${
        categoryFilter === id 
        ? 'bg-blue-700 text-white border-blue-600 shadow-lg shadow-blue-900/50 scale-105' 
        : 'bg-slate-900 text-slate-400 border-slate-700 hover:bg-slate-800 hover:text-white'
      }`}
    >
      {label}
    </button>
  );

  const filteredProducts = categoryFilter === 'all' 
    ? products 
    : products.filter(p => p.category === categoryFilter);

  // --- VISTA: ADMIN PANEL ---
  if (view === 'admin') {
    return (
      <div className="min-h-screen bg-slate-950 p-4 lg:p-8">
        <div className="max-w-5xl mx-auto bg-slate-900 rounded-3xl shadow-2xl border border-slate-800 overflow-hidden">
          {/* Header Admin */}
          <div className="bg-slate-950 p-6 border-b border-slate-800 flex justify-between items-center">
             <h2 className="text-2xl lg:text-3xl font-bold flex items-center gap-3 text-slate-100">
               <Settings className="w-8 h-8 text-blue-500" />
               Driver Inventory
             </h2>
             <button 
               onClick={() => setView('menu')}
               className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-6 py-2 rounded-full font-semibold transition-colors border border-slate-700"
             >
               Exit Admin Mode
             </button>
          </div>

          <div className="p-6 lg:p-8 flex flex-col lg:flex-row gap-8">
            {/* Columna Izquierda: Formulario */}
            <div className="flex-1 space-y-8">
              <div className="bg-slate-950/50 p-6 rounded-2xl border border-slate-800">
                <h3 className="text-xl font-bold text-blue-400 mb-6 flex items-center gap-2">
                  <Plus className="w-5 h-5" /> Add New Product
                </h3>
                
                <div className="space-y-4">
                  {/* Input Nombre */}
                  <div>
                    <label className="block text-sm font-medium text-slate-400 mb-1">Product Name</label>
                    <input 
                      type="text" 
                      value={newProduct.name}
                      onChange={(e) => setNewProduct({...newProduct, name: e.target.value})}
                      className="w-full p-3 rounded-lg bg-slate-800 border border-slate-700 text-white focus:ring-2 focus:ring-blue-500 outline-none"
                      placeholder="e.g. Water Bottle"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    {/* Input Precio */}
                    <div>
                      <label className="block text-sm font-medium text-slate-400 mb-1">Price ($)</label>
                      <input 
                        type="number" 
                        value={newProduct.price}
                        onChange={(e) => setNewProduct({...newProduct, price: e.target.value})}
                        className="w-full p-3 rounded-lg bg-slate-800 border border-slate-700 text-white focus:ring-2 focus:ring-blue-500 outline-none"
                        placeholder="0.00"
                      />
                    </div>
                    {/* Input Categoria */}
                    <div>
                      <label className="block text-sm font-medium text-slate-400 mb-1">Category</label>
                      <select 
                        value={newProduct.category}
                        onChange={(e) => setNewProduct({...newProduct, category: e.target.value})}
                        className="w-full p-3 rounded-lg bg-slate-800 border border-slate-700 text-white focus:ring-2 focus:ring-blue-500 outline-none"
                      >
                        <option value="drinks">Drinks</option>
                        <option value="snacks">Snacks</option>
                        <option value="essentials">Essentials</option>
                      </select>
                    </div>
                  </div>

                  {/* Input Imagen */}
                  <div>
                    <label className="block text-sm font-medium text-slate-400 mb-1">Product Image</label>
                    <div className="flex items-center gap-3">
                      <button 
                        onClick={() => fileInputRef.current.click()}
                        className="flex-1 p-3 bg-slate-800 border border-dashed border-slate-600 rounded-lg text-slate-400 hover:bg-slate-700 hover:border-blue-500 transition-colors flex items-center justify-center gap-2"
                      >
                        <Upload size={20} />
                        {newProduct.image ? "Change Image" : "Upload Image"}
                      </button>
                      <input 
                        type="file"
                        accept="image/*"
                        ref={fileInputRef}
                        onChange={handleImageUpload}
                        className="hidden"
                      />
                      {newProduct.image && (
                        <button 
                           onClick={() => {
                             setNewProduct({...newProduct, image: null});
                             if(fileInputRef.current) fileInputRef.current.value = "";
                           }}
                           className="p-3 text-red-400 bg-red-900/20 border border-red-900/30 rounded-lg hover:bg-red-900/30"
                        >
                          <Trash2 size={20} />
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Selector de Estilo de Imagen */}
                  {newProduct.image && (
                    <div className="bg-slate-800 p-3 rounded-lg border border-slate-700">
                      <label className="block text-sm font-medium text-slate-400 mb-2">Image Style</label>
                      <div className="flex gap-2">
                        <button
                          onClick={() => setNewProduct({ ...newProduct, imageFit: 'contain' })}
                          className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium flex items-center justify-center gap-2 transition-all ${
                            newProduct.imageFit === 'contain' 
                            ? 'bg-blue-900/40 text-blue-300 border border-blue-800' 
                            : 'bg-slate-700 text-slate-400 hover:bg-slate-600'
                          }`}
                        >
                          <Minimize size={16} />
                          Fit (Transparent)
                        </button>
                        <button
                          onClick={() => setNewProduct({ ...newProduct, imageFit: 'cover' })}
                          className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium flex items-center justify-center gap-2 transition-all ${
                            newProduct.imageFit === 'cover' 
                            ? 'bg-blue-900/40 text-blue-300 border border-blue-800' 
                            : 'bg-slate-700 text-slate-400 hover:bg-slate-600'
                          }`}
                        >
                          <Maximize size={16} />
                          Fill (Photo)
                        </button>
                      </div>
                      <p className="text-xs text-slate-500 mt-2">
                        {newProduct.imageFit === 'contain' 
                          ? "Best for PNGs without background."
                          : "Best for normal photos. Crops edges."
                        }
                      </p>
                    </div>
                  )}

                  <button 
                    onClick={handleAddProduct}
                    disabled={!newProduct.name || !newProduct.price}
                    className={`w-full p-4 rounded-xl font-bold transition-all flex justify-center items-center gap-2 mt-4 ${
                      !newProduct.name || !newProduct.price 
                      ? 'bg-slate-800 text-slate-500 cursor-not-allowed border border-slate-700' 
                      : 'bg-blue-600 hover:bg-blue-700 text-white shadow-lg hover:shadow-blue-900/50 border border-blue-500'
                    }`}
                  >
                    <Save size={20} /> Save Product
                  </button>
                </div>
              </div>
            </div>

            {/* Columna Derecha: Previsualización e Inventario */}
            <div className="w-full lg:w-1/3 flex flex-col gap-8">
               {/* Previsualización */}
               <div>
                  <h3 className="text-sm font-bold text-slate-500 uppercase tracking-wider mb-3">Live Preview</h3>
                  <div className="bg-slate-950/50 p-6 rounded-2xl border border-slate-800 flex justify-center items-center relative overflow-hidden">
                    <div className="absolute inset-0 opacity-20" style={{backgroundImage: 'radial-gradient(#475569 1px, transparent 1px)', backgroundSize: '10px 10px'}}></div>
                    
                    <div className="w-48 pointer-events-none transform scale-90 origin-center">
                       <ProductCard 
                          product={{
                            ...newProduct, 
                            // Simular color en preview
                            color: newProduct.category === 'drinks' ? 'bg-blue-900/40 text-blue-300' : newProduct.category === 'snacks' ? 'bg-orange-900/40 text-orange-300' : 'bg-purple-900/40 text-purple-300',
                            iconType: 'zap'
                          }} 
                          isPreview={true}
                       />
                    </div>
                  </div>
               </div>

               {/* Lista Rápida */}
               <div className="flex-1 bg-slate-900 border border-slate-800 rounded-2xl flex flex-col overflow-hidden h-80">
                 <div className="p-4 bg-slate-950 border-b border-slate-800 font-bold text-slate-300">
                   Inventory ({products.length})
                 </div>
                 <div className="overflow-y-auto p-2">
                   {products.map(p => (
                     <div key={p.id} className="flex items-center justify-between p-3 hover:bg-slate-800 rounded-lg border-b border-slate-800 last:border-0 transition-colors">
                       <div className="flex items-center gap-3">
                         <div className={`w-10 h-10 rounded-lg overflow-hidden flex items-center justify-center ${p.image ? 'bg-transparent' : 'bg-slate-800'}`}>
                            {p.image ? (
                              <img 
                                src={p.image} 
                                className={`w-full h-full ${p.imageFit === 'cover' ? 'object-cover' : 'object-contain'}`} 
                                alt="" 
                              />
                            ) : (
                              <div className="text-slate-400">
                                {getIcon(p.iconType, "w-5 h-5")}
                              </div>
                            )}
                         </div>
                         <div>
                           <div className="font-bold text-slate-200 text-sm">{p.name}</div>
                           <div className="text-xs text-slate-500">${p.price.toFixed(2)}</div>
                         </div>
                       </div>
                       <button 
                          onClick={() => handleDeleteProduct(p.id)}
                          className="text-red-400 hover:bg-red-900/20 p-2 rounded-lg transition-colors"
                       >
                         <Trash2 size={16} />
                       </button>
                     </div>
                   ))}
                 </div>
               </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // --- VISTA: MENU (Modificada con botón Admin) ---
  if (view === 'menu') {
    return (
      <div className="flex h-screen bg-slate-950 font-sans overflow-hidden text-slate-200">
        {/* Main Product Area */}
        <div className="flex-1 flex flex-col h-full">
          {/* Header */}
          <header className="bg-slate-900 p-4 lg:p-6 shadow-md z-10 flex flex-col lg:flex-row justify-between items-center gap-4 border-b border-slate-800">
            <div className="flex items-center gap-4 w-full lg:w-auto justify-between lg:justify-start">
              <div>
                <h1 className="text-2xl lg:text-3xl font-bold text-slate-100 tracking-tight">Ride Market</h1>
                <p className="text-sm lg:text-base text-slate-400">Refresh yourself during the ride</p>
              </div>
              {/* Botón Admin "Secreto" */}
              <button 
                onClick={() => setView('admin')}
                className="text-slate-600 hover:text-slate-400 p-2 transition-colors"
                title="Driver Settings"
              >
                <Settings size={24} />
              </button>
            </div>
            <div className="flex gap-2 overflow-x-auto w-full lg:w-auto pb-2 lg:pb-0">
               <CategoryButton id="all" label="All" />
               <CategoryButton id="drinks" label="Drinks" />
               <CategoryButton id="snacks" label="Snacks" />
               <CategoryButton id="essentials" label="Essentials" />
            </div>
          </header>

          {/* Product Grid */}
          <div className="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-950">
            <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 lg:gap-6 pb-24">
              {filteredProducts.map(product => (
                <ProductCard 
                  key={product.id} 
                  product={product} 
                  cartQuantity={cart.find(item => item.id === product.id)?.quantity || 0}
                  onAdd={() => addToCart(product)}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Cart Sidebar (Right) */}
        <div className="w-80 lg:w-96 bg-slate-900 shadow-2xl flex flex-col h-full z-20 border-l border-slate-800">
          <div className="p-6 bg-slate-900 border-b border-slate-800">
            <h2 className="text-2xl font-bold flex items-center gap-2 text-slate-100">
              <ShoppingCart className="w-6 h-6 text-blue-500" />
              Your Order
            </h2>
          </div>

          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {cart.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-slate-600 space-y-4 opacity-60">
                <ShoppingCart size={64} strokeWidth={1.5} />
                <p className="text-lg text-center">Your cart is empty.<br/>Tap items to start.</p>
              </div>
            ) : (
              cart.map(item => (
                <div key={item.id} className="flex items-center justify-between bg-slate-800 p-3 rounded-xl border border-slate-700 shadow-sm">
                  <div className="flex-1">
                    <h4 className="font-bold text-slate-200 text-sm lg:text-base">{item.name}</h4>
                    <p className="text-blue-400 font-medium">${(item.price * item.quantity).toFixed(2)}</p>
                  </div>
                  <div className="flex items-center gap-2 lg:gap-3 bg-slate-900 rounded-lg p-1 border border-slate-700">
                    <button 
                      onClick={(e) => { e.stopPropagation(); updateQuantity(item.id, -1); }}
                      className="w-8 h-8 flex items-center justify-center bg-slate-800 rounded text-slate-400 hover:bg-slate-700 hover:text-white transition-colors"
                    >
                      <Minus size={16} />
                    </button>
                    <span className="font-bold w-4 text-center text-slate-200">{item.quantity}</span>
                    <button 
                      onClick={(e) => { e.stopPropagation(); updateQuantity(item.id, 1); }}
                      className="w-8 h-8 flex items-center justify-center bg-slate-800 rounded text-blue-400 hover:bg-blue-900/30 hover:text-blue-300 transition-colors"
                    >
                      <Plus size={16} />
                    </button>
                  </div>
                  <button 
                    onClick={() => removeFromCart(item.id)}
                    className="ml-2 text-slate-600 hover:text-red-400 p-1 transition-colors"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              ))
            )}
          </div>

          <div className="p-6 bg-slate-900 border-t border-slate-800 space-y-4">
            <div className="flex justify-between text-xl font-bold text-slate-100">
              <span>Total</span>
              <span>${cartTotal.toFixed(2)}</span>
            </div>
            <button 
              onClick={handleCheckout}
              disabled={cart.length === 0}
              className={`w-full py-4 rounded-xl text-xl font-bold flex items-center justify-center gap-2 shadow-lg transition-all border ${
                cart.length === 0 
                ? 'bg-slate-800 text-slate-600 cursor-not-allowed border-slate-700' 
                : 'bg-blue-600 text-white hover:bg-blue-500 active:scale-95 border-blue-500 shadow-blue-900/20'
              }`}
            >
              <span>Pay Now</span>
              <ChevronLeft className="rotate-180" />
            </button>
          </div>
        </div>
      </div>
    );
  }

  // --- VIEW: PAYMENT ---
  if (view === 'payment') {
    return (
      <div className="h-screen w-screen bg-slate-950 flex items-center justify-center p-6 relative">
        <button 
          onClick={() => setView('menu')}
          className="absolute top-8 left-8 bg-slate-800 text-slate-200 p-4 rounded-full flex items-center gap-2 hover:bg-slate-700 transition-colors border border-slate-700"
        >
          <ChevronLeft size={32} />
          <span className="font-bold text-lg">Back to Menu</span>
        </button>

        <div className="bg-slate-900 w-full max-w-4xl h-[80vh] rounded-3xl overflow-hidden flex shadow-2xl border border-slate-800">
          <div className="w-1/2 bg-slate-900 p-8 lg:p-12 flex flex-col border-r border-slate-800">
            <h2 className="text-3xl font-bold text-slate-100 mb-8">Order Summary</h2>
            <div className="flex-1 overflow-y-auto space-y-4 pr-4">
              {cart.map(item => (
                <div key={item.id} className="flex justify-between items-center text-lg text-slate-300">
                  <div className="flex gap-3 items-center">
                    <span className="font-bold bg-blue-900/40 text-blue-300 px-3 py-1 rounded-md text-sm border border-blue-900/50">{item.quantity}x</span>
                    <span className="leading-tight">{item.name}</span>
                  </div>
                  <span className="font-medium text-slate-100 whitespace-nowrap ml-2">${(item.price * item.quantity).toFixed(2)}</span>
                </div>
              ))}
            </div>
            <div className="mt-8 pt-8 border-t-2 border-dashed border-slate-700">
              <div className="flex justify-between text-4xl font-bold text-blue-400">
                <span>Total</span>
                <span>${cartTotal.toFixed(2)}</span>
              </div>
            </div>
          </div>

          <div className="w-1/2 p-8 lg:p-12 flex flex-col items-center justify-center text-center relative bg-slate-950">
            {isProcessing ? (
              <div className="flex flex-col items-center animate-pulse">
                <div className="w-24 h-24 border-4 border-slate-700 border-t-blue-500 rounded-full animate-spin mb-6"></div>
                <h3 className="text-2xl font-bold text-slate-200">Opening Square...</h3>
                <p className="text-slate-500 mt-2">Check your Square App to complete payment</p>
              </div>
            ) : (
              <>
                <div className="bg-slate-800 p-4 rounded-2xl mb-6 shadow-xl border border-slate-700">
                   <CreditCard className="w-16 h-16 text-slate-300" />
                </div>
                <h2 className="text-3xl font-bold text-slate-100 mb-2">Complete Payment</h2>
                <p className="text-slate-400 text-lg mb-8 max-w-xs">
                  Tap below to open the Square Point of Sale app and process the payment of <strong className="text-white">${cartTotal.toFixed(2)}</strong>.
                </p>
                
                <button
                  onClick={handleSquarePayment}
                  className="w-full max-w-xs py-5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-bold text-xl shadow-lg shadow-blue-900/30 transform transition-all hover:scale-105 flex items-center justify-center gap-3 mb-6 border border-blue-500"
                >
                  <ExternalLink size={24} />
                  <span>Pay with Square App</span>
                </button>

                <div className="relative w-full max-w-xs border-t border-slate-800 my-4">
                   <span className="absolute top-[-10px] left-1/2 transform -translate-x-1/2 bg-slate-950 px-3 text-slate-600 text-sm">or</span>
                </div>

                <div className="flex flex-col items-center opacity-80">
                   <p className="text-sm text-slate-500 mb-2">Scan to pay on your phone</p>
                   <img 
                     src={`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://example.com/pay/${cartTotal}`} 
                     alt="Payment QR" 
                     className="w-24 h-24 rounded-lg border border-slate-700 opacity-80 hover:opacity-100 transition-opacity"
                   />
                   <button 
                    onClick={simulatePaymentSuccess}
                    className="mt-4 text-xs text-slate-600 hover:text-blue-400 underline"
                  >
                    (Simulate Success without Square)
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    );
  }

  // --- VIEW: SUCCESS ---
  if (view === 'success') {
    return (
      <div className="h-screen w-screen bg-emerald-900 flex flex-col items-center justify-center text-white p-6 text-center animate-in fade-in zoom-in duration-500">
        <div className="bg-white text-emerald-600 rounded-full p-6 mb-8 shadow-2xl animate-bounce">
          <CheckCircle size={120} />
        </div>
        <h1 className="text-6xl font-bold mb-4">Payment Successful!</h1>
        <p className="text-2xl opacity-90 mb-12 text-emerald-100">Please take your items.</p>
        <p className="mt-12 text-lg opacity-60 text-emerald-200">Returning to menu shortly...</p>
      </div>
    );
  }

  return null;
};

export default KioscoApp;

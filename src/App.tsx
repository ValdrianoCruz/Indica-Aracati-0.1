import { useState, useEffect, FormEvent } from 'react';
import { 
  Phone, 
  Star, 
  ShieldAlert, 
  AlertTriangle, 
  MessageSquare, 
  Mail, 
  Search, 
  X, 
  Check, 
  ChevronRight,
  Info,
  ArrowLeft,
  User,
  MapPin,
  Briefcase
} from 'lucide-react';
import { Professional, DenounceReason } from './types';

export default function App() {
  // Screen routing state: 'Home' or 'Cadastro'
  const [currentScreen, setCurrentScreen] = useState<'Home' | 'Cadastro'>('Home');

  // Hardcoded real starting professionals as specified
  const initialProfessionals: Professional[] = [];

  // Combined live professionals state list
  const [professionals, setProfessionals] = useState<Professional[]>([]);

  // Form input states
  const [nomeCompleto, setNomeCompleto] = useState('');
  const [profissao, setProfissao] = useState('');
  const [bairro, setBairro] = useState('');
  const [whatsapp, setWhatsapp] = useState('');

  // Form error UI trigger state
  const [formError, setFormError] = useState<string | null>(null);

  // General App filters
  const [searchTerm, setSearchTerm] = useState('');
  const [denouncingProfessional, setDenouncingProfessional] = useState<Professional | null>(null);
  const [denounceReason, setDenounceReason] = useState<DenounceReason | null>(null);
  const [denounceDesc, setDenounceDesc] = useState('');
  const [denounceContact, setDenounceContact] = useState('');
  const [denounceError, setDenounceError] = useState<string | null>(null);
  const [showDenounceSuccess, setShowDenounceSuccess] = useState(false);
  const [showScamWarning, setShowScamWarning] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [ratingProfessional, setRatingProfessional] = useState<Professional | null>(null);
  const [chosenRating, setChosenRating] = useState<number>(5);
  
  // Custom alerts and toast states
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [currentTime, setCurrentTime] = useState('13:36');

  // Load local database on initialization
  useEffect(() => {
    let dynamicProfessionals: Professional[] = [];
    let ratingOverrides: Record<string, { rating: number; reviewsCount: number }> = {};
    
    try {
      const saved = localStorage.getItem('indica_aracati_professionals');
      if (saved) {
        dynamicProfessionals = JSON.parse(saved);
      }
    } catch (e) {
      console.warn('localStorage is blocked or unavailable:', e);
    }

    // Ensure all dynamic professionals have a registrationCode
    let modifiedDynamic = false;
    const len = dynamicProfessionals.length;
    for (let i = 0; i < len; i++) {
      const idx = len - 1 - i; // oldest is i = 0, so idx = len - 1
      const prof = dynamicProfessionals[idx];
      if (!prof.registrationCode) {
        const numStr = String(i + 1).padStart(2, '0');
        prof.registrationCode = numStr;
        modifiedDynamic = true;
      }
    }

    if (modifiedDynamic) {
      try {
        localStorage.setItem('indica_aracati_professionals', JSON.stringify(dynamicProfessionals));
        localStorage.setItem('indica_aracati_registration_counter', String(len));
      } catch (e) {
        console.warn('Could not save updated codes:', e);
      }
    }

    try {
      const savedRatings = localStorage.getItem('indica_aracati_ratings');
      if (savedRatings) {
        ratingOverrides = JSON.parse(savedRatings);
      }
    } catch (e) {
      console.warn('localStorage is blocked or unavailable:', e);
    }

    // Combine them all and apply rating overrides if any exist
    const combined = [...dynamicProfessionals, ...initialProfessionals].map(prof => {
      if (ratingOverrides[prof.id]) {
        return {
          ...prof,
          rating: ratingOverrides[prof.id].rating,
          reviewsCount: ratingOverrides[prof.id].reviewsCount
        };
      }
      return prof;
    });

    setProfessionals(combined);
  }, []);

  // Sync realistic clock
  useEffect(() => {
    const updateClock = () => {
      const now = new Date();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      setCurrentTime(`${hours}:${minutes}`);
    };
    updateClock();
    const interval = setInterval(updateClock, 30000);
    return () => clearInterval(interval);
  }, []);

  // Sensory UI toast
  const showFeedback = (message: string) => {
    setToastMessage(message);
    setTimeout(() => {
      setToastMessage(null);
    }, 4000);
  };

  // Safe client-side trigger to email app draft
  const triggerEmail = (to: string, subject: string, body: string, actionName: string) => {
    const encodedSubject = encodeURIComponent(subject);
    const encodedBody = encodeURIComponent(body);
    const mailtoUrl = `mailto:${to}?subject=${encodedSubject}&body=${encodedBody}`;
    
    showFeedback(`Abrindo e-mail de ${actionName}...`);
    setTimeout(() => {
      window.location.href = mailtoUrl;
    }, 600);
  };

  // Triggering cadastro screen transition
  const handleOpenCadastro = () => {
    setFormError(null);
    setCurrentScreen('Cadastro');
  };

  // 2. Botão "CONFIRMAR CADASTRO" na Tela_Cadastro
  const handleConfirmCadastro = (e: FormEvent) => {
    e.preventDefault();

    // Field sanitizations & validations
    const cleanNome = nomeCompleto.trim();
    const cleanProfissao = profissao.trim();
    const cleanBairro = bairro.trim();
    const cleanWhatsapp = whatsapp.trim().replace(/\D/g, ''); // numerical digits only

    if (!cleanNome || !cleanProfissao || !cleanBairro || !cleanWhatsapp) {
      setFormError('Preencha todos os campos obrigatórios');
      return;
    }

    if (cleanWhatsapp.length < 8) {
      setFormError('Por favor, informe um número de Whatsapp válido com DDD.');
      return;
    }

    // Process new dynamic professional object
    let nextNum = 1;
    try {
      const savedCounter = localStorage.getItem('indica_aracati_registration_counter');
      if (savedCounter) {
        nextNum = parseInt(savedCounter, 10) + 1;
      } else {
        const saved = localStorage.getItem('indica_aracati_professionals');
        const dynamicList: Professional[] = saved ? JSON.parse(saved) : [];
        nextNum = dynamicList.length + 1;
      }
      localStorage.setItem('indica_aracati_registration_counter', String(nextNum));
    } catch (e) {
      console.warn('localStorage is blocked or unavailable:', e);
    }

    const regCode = String(nextNum).padStart(2, '0');

    const newProf: Professional = {
      id: `user-prof-${Date.now()}`,
      name: cleanNome,
      occupation: cleanProfissao,
      rating: 5.0,
      reviewsCount: 0,
      location: cleanBairro,
      whatsappNumber: cleanWhatsapp,
      whatsappUrl: `https://wa.me/55${cleanWhatsapp}?text=Olá, vi seu perfil no Indica Aracati`,
      isNew: true,
      registrationCode: regCode
    };

    // Save locally via localStorage ('Stored Variables')
    let updatedList = [newProf];
    try {
      const saved = localStorage.getItem('indica_aracati_professionals');
      const dynamicList: Professional[] = saved ? JSON.parse(saved) : [];
      updatedList = [newProf, ...dynamicList];
      localStorage.setItem('indica_aracati_professionals', JSON.stringify(updatedList));
    } catch (e) {
      console.warn('localStorage is blocked or unavailable:', e);
    }

    // Update state to render on real-time screen (new registration appears on top of the list)
    setProfessionals([...updatedList, ...initialProfessionals]);

    // Send automatic email via EmailJS API as requested
    showFeedback('Enviando cadastro para a central...');
    
    fetch('https://api.emailjs.com/api/v1.0/email/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        service_id: 'service_xes2c0h',
        template_id: 'template_zulox6r', 
        user_id: 'XLPbHHChe_U6PfdQR',
        template_params: {
          // Chaves em português
          nome: cleanNome,
          profissao: cleanProfissao,
          bairro: cleanBairro,
          whatsapp: cleanWhatsapp,
          contato: cleanWhatsapp,

          // Chaves em inglês e variações comuns
          name: cleanNome,
          occupation: cleanProfissao,
          profession: cleanProfissao,
          bairro_nome: cleanBairro,
          neighborhood: cleanBairro,
          location: cleanBairro,
          phone: cleanWhatsapp,
          whatsapp_number: cleanWhatsapp,
          contact: cleanWhatsapp,

          // Campos clássicos/padrão do EmailJS para roteamento do destinatário
          to_email: "indicaaracati@gmail.com",
          admin_email: "indicaaracati@gmail.com",
          email_to: "indicaaracati@gmail.com",
          email: "indicaaracati@gmail.com",
          destinatario: "indicaaracati@gmail.com",
          to_name: "Administrador Indica Aracati",
          reply_to: "indicaaracati@gmail.com",
          subject: "Novo Cadastro Indica Aracati",
          assunto: "Novo Cadastro Indica Aracati",
          message: `Novo profissional cadastrado:\nNome: ${cleanNome}\nProfissão: ${cleanProfissao}\nBairro: ${cleanBairro}\nWhatsApp: ${cleanWhatsapp}`,
          mensagem: `Novo profissional cadastrado:\nNome: ${cleanNome}\nProfissão: ${cleanProfissao}\nBairro: ${cleanBairro}\nWhatsApp: ${cleanWhatsapp}`,
          corpo: `Novo profissional cadastrado:\nNome: ${cleanNome}\nProfissão: ${cleanProfissao}\nBairro: ${cleanBairro}\nWhatsApp: ${cleanWhatsapp}`
        }
      })
    })
    .then(async res => {
      if (!res.ok) {
        const errText = await res.text();
        console.error('EmailJS cadastro API returned non-ok:', res.status, errText);
      } else {
        console.log('EmailJS cadastro API successfully sent!');
      }
    })
    .catch(err => {
      console.error('EmailJS catch errors:', err);
    });

    // Reset input fields
    setNomeCompleto('');
    setProfissao('');
    setBairro('');
    setWhatsapp('');
    setFormError(null);

    // Show friendly alerts feedback
    setShowSuccessModal(true);
    setCurrentScreen('Home');
  };

  // Botões "Chamar no WhatsApp" redirect link launcher
  const handleWhatsAppRedirect = (prof: Professional) => {
    showFeedback(`Unindo chamada para ${prof.name}...`);
    setTimeout(() => {
      window.open(prof.whatsappUrl, '_blank', 'noopener,noreferrer');
    }, 450);
  };

  // Botões "⭐ Avaliar" custom action
  const handleRateProfessional = (prof: Professional) => {
    setRatingProfessional(prof);
    setChosenRating(5);
  };

  // Confirm and calculate new average rating from 1 to 5
  const handleConfirmRating = () => {
    if (!ratingProfessional) return;

    const currentRating = ratingProfessional.rating || 5.0;
    const currentCount = ratingProfessional.reviewsCount || 0;
    const newCount = currentCount + 1;
    const newRating = parseFloat(((currentRating * currentCount + chosenRating) / newCount).toFixed(1));

    // Update state to render in real-time
    setProfessionals(prev => prev.map(p => {
      if (p.id === ratingProfessional.id) {
        return {
          ...p,
          rating: newRating,
          reviewsCount: newCount
        };
      }
      return p;
    }));

    // Save locally under ratings overrides
    try {
      const savedRatings = localStorage.getItem('indica_aracati_ratings');
      const ratingOverrides = savedRatings ? JSON.parse(savedRatings) : {};
      ratingOverrides[ratingProfessional.id] = { rating: newRating, reviewsCount: newCount };
      localStorage.setItem('indica_aracati_ratings', JSON.stringify(ratingOverrides));
    } catch (e) {
      console.warn('Could not save rating overrides:', e);
    }

    // Show success toast feedback
    showFeedback(`Avaliação de ${chosenRating} estrelas registrada com sucesso!`);
    
    // Close modal
    setRatingProfessional(null);
  };

  // Botões "⚠️ Denunciar" click action
  const handleDenounceClick = (prof: Professional) => {
    setDenouncingProfessional(prof);
    setDenounceReason(null);
    setDenounceDesc('');
    setDenounceContact('');
    setDenounceError(null);
  };

  // Select Denunciation Choice and step to user details inputs
  const handleSelectDenounceReason = (reason: DenounceReason) => {
    setDenounceReason(reason);
    setDenounceDesc('');
    setDenounceContact('');
    setDenounceError(null);
  };

  // Submit automated denunciation via EmailJS API
  const handleConfirmDenounce = (e: FormEvent) => {
    e.preventDefault();
    if (!denouncingProfessional || !denounceReason) return;

    const cleanContact = denounceContact.trim();

    if (!cleanContact) {
      setDenounceError('Informe seu número de contato.');
      return;
    }

    const cleanDesc = `Denúncia efetuada via aplicativo. Motivo selecionado: ${denounceReason}`;

    showFeedback('Enviando denúncia com segurança...');

    // CHAMAR WEB API para enviar e-mail automático via EmailJS
    fetch('https://api.emailjs.com/api/v1.0/email/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        service_id: 'service_xes2c0h',
        template_id: 'template_sb9zxv9',
        user_id: 'XLPbHHChe_U6PfdQR',
        template_params: {
          // Parâmetros principais solicitados
          profissional: denouncingProfessional.name,
          motivo: denounceReason,
          descricao: cleanDesc,
          contato: cleanContact,

          // Redundâncias em português e inglês
          professional: denouncingProfessional.name,
          name: denouncingProfessional.name,
          reason: denounceReason,
          description: cleanDesc,
          contact: cleanContact,
          whatsapp: cleanContact,

          // Campos clássicos/padrão do EmailJS para roteamento do destinatário
          to_email: "indicaaracati@gmail.com",
          admin_email: "indicaaracati@gmail.com",
          email_to: "indicaaracati@gmail.com",
          email: "indicaaracati@gmail.com",
          destinatario: "indicaaracati@gmail.com",
          to_name: "Administrador Indica Aracati",
          reply_to: "indicaaracati@gmail.com",
          subject: `Denúncia - ${denouncingProfessional.name} (${denounceReason})`,
          assunto: `Denúncia - ${denouncingProfessional.name} (${denounceReason})`,
          message: `Nova denúncia enviada para Indica Aracati:\nProfissional: ${denouncingProfessional.name}\nMotivo: ${denounceReason}\nDescrição: ${cleanDesc}\nContato: ${cleanContact}`,
          mensagem: `Nova denúncia enviada para Indica Aracati:\nProfissional: ${denouncingProfessional.name}\nMotivo: ${denounceReason}\nDescrição: ${cleanDesc}\nContato: ${cleanContact}`,
          corpo: `Nova denúncia enviada para Indica Aracati:\nProfissional: ${denouncingProfessional.name}\nMotivo: ${denounceReason}\nDescrição: ${cleanDesc}\nContato: ${cleanContact}`
        }
      })
    })
    .then(async res => {
      if (!res.ok) {
        const errText = await res.text();
        console.error('EmailJS denúncia API returned non-ok:', res.status, errText);
      } else {
        console.log('EmailJS denúncia API successfully sent!');
      }
    })
    .catch(err => {
      console.error('EmailJS denúncia catch errors:', err);
    });

    // Reset and close
    setDenouncingProfessional(null);
    setDenounceReason(null);
    setDenounceDesc('');
    setDenounceContact('');
    setDenounceError(null);

    // Show alert "Denúncia enviada. Obrigado por ajudar a manter o app seguro."
    setShowDenounceSuccess(true);
  };

  // Footer Button 1: 💬 Sugestões
  const handleSuggestions = () => {
    const body = "Mensagem:\n";
    triggerEmail(
      'indicaaracati@gmail.com',
      'Sugestão/Elogio Indica Aracati',
      body,
      'sugestão'
    );
  };

  // Footer Button 3: ⭐ Avaliar o App
  const handleRateApp = () => {
    const body = "Nota de 1 a 5:\nO que gostou:\nO que podemos melhorar:";
    triggerEmail(
      'indicaaracati@gmail.com',
      'Avaliação do App Indica Aracati',
      body,
      'avaliar o aplicativo'
    );
  };

  // Apply real-time query filtering across data
  const filteredProfessionals = professionals.filter(p => {
    const term = searchTerm.toLowerCase();
    return p.name.toLowerCase().includes(term) || 
           p.occupation.toLowerCase().includes(term) ||
           p.location.toLowerCase().includes(term);
  });

  return (
    <div className="min-h-screen bg-[#f0f0f0] flex flex-col items-center justify-start py-0 sm:py-6 font-sans select-none">
      {/* Device frame structure optimized for simple reading and elderly density */}
      <div className="w-full max-w-[480px] sm:h-[768px] h-screen bg-white shadow-2xl overflow-hidden flex flex-col relative sm:rounded-2xl border-0 sm:border-4 sm:border-gray-300">
        
        {/* Android system top state bar emulator for look-and-feel of built APK */}
        <div className="hidden sm:flex bg-[#FF6B00] text-[#FFE8D6] px-4 pt-2 pb-1 justify-between items-center text-[11px] font-bold shrink-0">
          <span>{currentTime}</span>
          <div className="flex items-center space-x-1.5">
            <span className="text-[10px]">98%</span>
            <div className="w-4 h-2 border border-orange-200 rounded-[1px] p-[1.5px] flex items-center">
              <div className="bg-white h-full w-[85%] rounded-[1px]" />
            </div>
            <span className="text-[9px] tracking-widest font-black">5G</span>
          </div>
        </div>

        {/* Dynamic header conditional based on visual screen level */}
        {currentScreen === 'Home' ? (
          /* Main Screen Header: Laranja #FF6B00, altura 80px. TEXTO "INDICA ARACATI" cor branca, tam 24, negrito, centralizado */
          <header id="screen-home-header" className="h-[80px] bg-[#FF6B00] flex items-center justify-between px-4 shrink-0 shadow-xs relative">
            <div className="w-8"></div> {/* Symmetry spaceholder */}
            <h1 className="text-white text-[24px] font-bold tracking-wider text-center flex-1 uppercase">
              INDICA ARACATI
            </h1>
            <button
              onClick={() => setShowScamWarning(true)}
              className="p-1.5 rounded-full bg-orange-700/20 hover:bg-orange-800/30 text-white transition-all cursor-pointer"
              title="Aviso contra golpes e ligar dicas"
            >
              <ShieldAlert className="w-5.5 h-5.5" />
            </button>
          </header>
        ) : (
          /* Cadastro Screen Header: Laranja #FF6B00 com texto "Cadastro de Profissional" + botão voltar */
          <header id="screen-cadastro-header" className="h-[80px] bg-[#FF6B00] flex items-center justify-between px-4 shrink-0 shadow-xs">
            <button
              onClick={() => { setCurrentScreen('Home'); setFormError(null); }}
              className="flex items-center justify-center p-2 text-white hover:bg-orange-600 rounded-full transition-colors cursor-pointer"
              aria-label="Voltar para tela inicial"
            >
              <ArrowLeft className="w-6 h-6" />
            </button>
            <h1 className="text-white text-[19px] sm:text-[21px] font-bold tracking-wide text-center uppercase flex-1 mr-6">
              Cadastro de Profissional
            </h1>
          </header>
        )}

        {/* Sub-header offline/security active tag status */}
        <div className="bg-orange-50 border-b border-orange-100 px-4 py-1 flex items-center justify-center shrink-0">
          <span className="w-2 h-2 rounded-full bg-green-500 animate-ping mr-2"></span>
          <p className="text-[11px] font-bold text-orange-950 uppercase tracking-wider">
            Canal de Recomendação Livre de Golpes 🇧🇷
          </p>
        </div>

        {/* APP MAIN BODY CONTENT SWITCH */}
        <div className="flex-1 overflow-y-auto flex flex-col bg-white">
          
          {currentScreen === 'Home' ? (
            /* ==================== SCREEN 1: INDEX TELA INICIAL ==================== */
            <div className="flex-1 flex flex-col px-4 py-[15px]">
              
              {/* Espaçamento 15px is automatically native to layout container */}

              {/* Botão principal: "QUERO ME CADASTRAR - 100% GRÁTIS", cor fundo #FF6B00FF, cor texto branco, largura 90% (w-11/12), altura 50px, cantos arredondados 10px */}
              <div className="flex justify-center w-full mb-3.5 shrink-0">
                <button
                  id="btn-register-action"
                  onClick={handleOpenCadastro}
                  className="w-[90%] h-[50px] bg-[#FF6B00] hover:bg-orange-600 active:scale-[0.98] text-white font-extrabold text-[13px] sm:text-[14px] rounded-[10px] tracking-wide shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer text-center"
                >
                  <Mail className="w-4 h-4 shrink-0" />
                  <span>QUERO ME CADASTRAR - 100% GRÁTIS</span>
                </button>
              </div>

              {/* Extra Senior Advisory support helper to assist readability */}
              <div className="bg-orange-50/60 p-2.5 rounded-lg border border-orange-100 flex items-start gap-2 text-[12px] text-orange-900 leading-snug mb-3">
                <Info className="w-4 h-4 text-[#FF6B00] shrink-0 mt-0.5" />
                <p>
                  <strong>Dica:</strong> Toque no botão verde <strong className="text-green-700 font-bold">Chamar no WhatsApp</strong> para abrir sua conversa imediatamente.
                </p>
              </div>

              {/* Filter tools: Dynamic searching */}
              <div className="bg-gray-50 border border-gray-150 rounded-lg p-2.5 mb-4">
                <div className="flex items-center bg-white border border-gray-300 rounded-md px-2.5 py-1.5 focus-within:ring-2 focus-within:ring-orange-500">
                  <Search className="text-gray-400 w-4 h-4 mr-2" />
                  <input
                    type="text"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    placeholder="Filtrar por nome, profissão ou bairro..."
                    className="bg-transparent border-0 outline-none w-full text-[13px] text-gray-800"
                  />
                  {searchTerm && (
                    <button onClick={() => setSearchTerm('')} className="p-0.5 hover:bg-gray-100 rounded-full">
                      <X className="w-3.5 h-3.5 text-gray-400" />
                    </button>
                  )}
                </div>
              </div>

              {/* Rótulo: "Profissionais em destaque:", tamanho 18, negrito, cor #333333 */}
              <div className="mb-3 flex justify-between items-center shrink-0 px-1">
                <h2 className="text-[17px] sm:text-[18px] font-bold text-[#333333]">
                  Profissionais em destaque:
                </h2>
                <span className="text-[11px] bg-slate-100 text-slate-700 px-2 py-0.5 rounded font-bold">
                  {filteredProfessionals.length} perfis
                </span>
              </div>

              {/* PROFESSIONALS DYNAMIC CARDS CONTAINER */}
              <div className="flex flex-col gap-3.5 w-full">
                {filteredProfessionals.length > 0 ? (
                  filteredProfessionals.map((prof) => (
                    /* General style: Borda cinza claro #E0E0E0, cantos 8px, largura 90% (w-[90%]), padding 15px */
                    <div
                      key={prof.id}
                      id={`card-${prof.id}`}
                      className={`w-[90%] mx-auto bg-white border-2 rounded-[8px] p-[15px] shadow-sm relative transition-shadow ${
                        prof.isNew ? 'border-[#4CAF50] bg-green-50/10' : 'border-[#E0E0E0]'
                      }`}
                    >
                      {/* Top Tag badges */}
                      <div className="absolute top-2.5 right-3 flex items-center gap-1.5">
                        <span className="bg-slate-100 text-slate-500 text-[9px] font-bold px-1.5 py-0.5 rounded uppercase">
                          RECOMENDADO
                        </span>
                      </div>

                      {/* Rótulo 1: "[Nome] - [Profissão]" tamanho 16, negrito, cor #000000 */}
                      <div className="pr-16 leading-snug">
                        <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
                          <p className="text-[16px] font-bold text-black">
                            {prof.name} - {prof.occupation}
                          </p>
                          {prof.registrationCode && (
                            <span className="text-[11px] font-extrabold uppercase bg-orange-100 text-[#FF6B00] border border-orange-200 px-1.5 py-0.5 rounded tracking-wide whitespace-nowrap">
                              Nº {prof.registrationCode}
                            </span>
                          )}
                        </div>
                      </div>

                      {/* Rótulo 2: "⭐ 4.8 | 15 avaliações | [Bairro]" tamanho 14, cor #666666 */}
                      <p className="text-[14px] text-[#666666] mt-1 mb-3.5 leading-none flex items-center gap-1 flex-wrap">
                        <span className="text-yellow-500 font-extrabold">⭐</span>
                        <span className="font-bold text-gray-800">{prof.rating}</span>
                        <span className="text-gray-300">|</span>
                        <span>{prof.reviewsCount} avaliações</span>
                        <span className="text-gray-300">|</span>
                        <span className="font-bold text-orange-700 bg-orange-50 px-1.5 rounded">{prof.location}</span>
                      </p>

                      {/* Action buttons list */}
                      <div className="space-y-2 select-none">
                        {/* Botão 1: "Chamar no WhatsApp" cor fundo #25D366FF, cor texto branco, largura 100%, altura 45px */}
                        <button
                          onClick={() => handleWhatsAppRedirect(prof)}
                          className="w-full h-[45px] bg-[#25D366] hover:bg-green-600 text-white font-bold rounded text-[13.5px] uppercase tracking-wide flex items-center justify-center gap-2 transition-all active:scale-[0.99] cursor-pointer"
                        >
                          <Phone className="w-4.5 h-4.5 shrink-0 fill-current" />
                          <span>Chamar no WhatsApp</span>
                        </button>

                        <div className="flex justify-between items-center w-full">
                          {/* Botão 2: "⭐ Avaliar [Nome]" cor fundo #FFA500FF, cor texto branco, largura 48%, altura 40px */}
                          <button
                            onClick={() => handleRateProfessional(prof)}
                            className="w-[48%] h-[40px] bg-[#FFA500] hover:bg-amber-600 text-white text-[12px] flex items-center justify-center rounded font-bold cursor-pointer transition-colors"
                          >
                            <span className="truncate">⭐ Avaliar {prof.name.split(' ')[0]}</span>
                          </button>

                          {/* Botão 3: "⚠️ Denunciar" cor fundo #D32F2FFF, cor texto branco, largura 48%, altura 40px */}
                          <button
                            onClick={() => handleDenounceClick(prof)}
                            className="w-[48%] h-[40px] bg-[#D32F2F] hover:bg-red-700 text-white text-[12px] flex items-center justify-center rounded font-bold cursor-pointer transition-colors"
                          >
                            <span>⚠️ Denunciar</span>
                          </button>
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="p-8 text-center bg-gray-50 border border-dashed border-gray-300 rounded-lg mx-auto w-[90%] select-none">
                    <p className="text-[13px] text-gray-500 font-bold mb-1">Nenhum profissional encontrado.</p>
                    <p className="text-[11px] text-gray-400 mb-2">Tente outra busca ou categoria.</p>
                    <button
                      onClick={() => { setSearchTerm(''); }}
                      className="px-3 py-1 bg-[#FF6B00] text-white text-[11px] font-bold rounded"
                    >
                      Ver todos os cadastros
                    </button>
                  </div>
                )}
              </div>

            </div>
          ) : (
            /* ==================== SCREEN 2: TELA_CADASTRO ==================== */
            <div className="flex-1 flex flex-col p-5">
              
              <div className="bg-orange-50 border-1 border-orange-200 text-orange-950 p-3.5 rounded-lg text-[12.5px] leading-relaxed mb-4">
                <p>
                  <strong>Cadastre-se totalmente grátis!</strong> Seu perfil de serviço será adicionado imediatamente à lista para milhares de pessoas em Aracati verem. Todos os campos com <strong className="text-red-650 font-black">*</strong> são obrigatórios.
                </p>
              </div>

              {/* Form container */}
              <form onSubmit={handleConfirmCadastro} className="flex-1 flex flex-col space-y-4">
                
                {formError && (
                  <div className="bg-red-50 border border-red-200 text-red-750 p-3 rounded-lg text-[13px] font-bold flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4 shrink-0 text-red-650" />
                    <span>{formError}</span>
                  </div>
                )}

                {/* Campo de texto 1: Rótulo "Nome Completo *" + Caixa de texto com dica "Digite seu nome" */}
                <div className="space-y-1">
                  <label htmlFor="input-nome" className="block text-[13.5px] font-bold text-gray-800">
                    Nome Completo <span className="text-red-500">*</span>
                  </label>
                  <div className="flex items-center bg-white border border-gray-300 focus-within:ring-2 focus-within:ring-orange-500 rounded-md px-3 py-2">
                    <User className="text-gray-400 w-4 h-4 mr-2" />
                    <input
                      id="input-nome"
                      type="text"
                      value={nomeCompleto}
                      onChange={(e) => setNomeCompleto(e.target.value)}
                      placeholder="Digite seu nome"
                      className="bg-transparent border-0 outline-none w-full text-[14px] text-gray-800"
                    />
                  </div>
                </div>

                {/* Campo de texto 2: Rótulo "Profissão *" + Caixa de texto com dica "Ex: Eletricista, Pedreiro" */}
                <div className="space-y-1">
                  <label htmlFor="input-profissao" className="block text-[13.5px] font-bold text-gray-800">
                    Profissão <span className="text-red-500">*</span>
                  </label>
                  <div className="flex items-center bg-white border border-gray-300 focus-within:ring-2 focus-within:ring-orange-500 rounded-md px-3 py-2">
                    <Briefcase className="text-gray-400 w-4 h-4 mr-2" />
                    <input
                      id="input-profissao"
                      type="text"
                      value={profissao}
                      onChange={(e) => setProfissao(e.target.value)}
                      placeholder="Ex: Eletricista, Pedreiro"
                      className="bg-transparent border-0 outline-none w-full text-[14px] text-gray-800"
                    />
                  </div>
                </div>

                {/* Campo de texto 3: Rótulo "Bairro *" + Caixa de texto com dica "Ex: Centro, Várzea" */}
                <div className="space-y-1">
                  <label htmlFor="input-bairro" className="block text-[13.5px] font-bold text-gray-800">
                    Bairro <span className="text-red-500">*</span>
                  </label>
                  <div className="flex items-center bg-white border border-gray-300 focus-within:ring-2 focus-within:ring-orange-500 rounded-md px-3 py-2">
                    <MapPin className="text-gray-400 w-4 h-4 mr-2" />
                    <input
                      id="input-bairro"
                      type="text"
                      value={bairro}
                      onChange={(e) => setBairro(e.target.value)}
                      placeholder="Ex: Centro, Várzea"
                      className="bg-transparent border-0 outline-none w-full text-[14px] text-gray-800"
                    />
                  </div>
                </div>

                {/* Campo de texto 4: Rótulo "WhatsApp com DDD *" + Caixa de texto numérica com dica "88999999999" */}
                <div className="space-y-1 flex-1">
                  <label htmlFor="input-whatsapp" className="block text-[13.5px] font-bold text-gray-800">
                    WhatsApp com DDD <span className="text-red-500">*</span>
                  </label>
                  <div className="flex items-center bg-white border border-gray-300 focus-within:ring-2 focus-within:ring-orange-500 rounded-md px-3 py-2">
                    <Phone className="text-gray-400 w-4 h-4 mr-2" />
                    <input
                      id="input-whatsapp"
                      type="tel"
                      value={whatsapp}
                      onChange={(e) => setWhatsapp(e.target.value)}
                      placeholder="88999999999"
                      className="bg-transparent border-0 outline-none w-full text-[14px] text-gray-800"
                    />
                  </div>
                  <p className="text-[11px] text-gray-400 font-medium">Digite apenas números com o DDD da região de Aracati (Ex: 88)</p>
                </div>

                {/* Botão: "CONFIRMAR CADASTRO" cor #4CAF50FF, texto branco, largura 90% (w-[90%]), altura 50px */}
                <div className="flex justify-center w-full pt-4 pb-2">
                  <button
                    id="btn-confirm-register"
                    type="submit"
                    className="w-[90%] h-[50px] bg-[#4CAF50] hover:bg-green-600 active:scale-95 text-white text-[15px] font-bold rounded-[10px] shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer uppercase shrink-0"
                  >
                    <Check className="w-5 h-5 shrink-0" />
                    <span>CONFIRMAR CADASTRO</span>
                  </button>
                </div>

                {/* Cancel link */}
                <button
                  type="button"
                  onClick={() => { setCurrentScreen('Home'); setFormError(null); }}
                  className="w-full text-center text-[12px] text-gray-500 hover:text-orange-600 py-1 cursor-pointer underline font-medium"
                >
                  Voltar para lista de profissionais
                </button>

              </form>

            </div>
          )}

        </div>

        {/* BOTTOM FIXED AREA (Consolidated design layout for high density viewports) */}
        <footer className="shrink-0 bg-white border-t border-gray-200 z-10 shadow-lg">
          
          {/* RODAPÉ DE SUPORTE - 3 BOTÕES LADO A LADO (above AdMob):
              Linha com 3 botões pequenos, largura 30% cada */}
          <div className="flex justify-between px-2 py-2 gap-1 bg-white select-none">
            {/* 1. Botão "💬 Sugestões" cor #2196F3, texto branco */}
            <button
              id="btn-footer-suggest"
              onClick={handleSuggestions}
              className="w-[32%] h-[45px] bg-[#2196F3] hover:bg-blue-600 text-white text-[10px] flex items-center justify-center rounded text-center leading-none px-1 font-bold cursor-pointer transition-colors"
            >
              💬 Sugestões
            </button>

            {/* 2. Botão "🛡️ Cuidado com Golpes" cor fundo #FF6B00, texto branco */}
            <button
              id="btn-footer-scam-tips"
              onClick={() => setShowScamWarning(true)}
              className="w-[32%] h-[45px] bg-[#FF6B00] hover:bg-orange-600 text-white text-[10px] flex items-center justify-center rounded text-center leading-none px-1 font-bold uppercase cursor-pointer transition-colors"
            >
              🛡️ Cuidado com Golpes
            </button>

            {/* 3. Botão "⭐ Avaliar o App" cor fundo #4CAF50, texto branco */}
            <button
              id="btn-footer-rate-app"
              onClick={handleRateApp}
              className="w-[32%] h-[45px] bg-[#4CAF50] hover:bg-green-600 text-white text-[10px] flex items-center justify-center rounded text-center leading-none px-1 font-bold uppercase cursor-pointer transition-colors"
            >
              ⭐ Avaliar o App
            </button>
          </div>

          {/* ADMOB BANNER - Exact specifications with fixed dimensions & compliant text */}
          <div className="h-[50px] bg-black flex flex-col items-center justify-center border-y border-gray-800 px-2 select-none">
            <span className="text-[#6c6c6c] text-[8.5px] font-mono leading-none tracking-tight">
              AdMob App ID: ca-app-pub-8462146539404027~9486146382
            </span>
            <span className="text-white text-[9.5px] font-bold mt-1 tracking-wide uppercase text-center truncate">
              AdMob Banner ID: ca-app-pub-8462146539404027/2392078829
            </span>
          </div>

          {/* COPYRIGHT AREA */}
          <div className="py-2.5 bg-white border-t border-gray-100 px-2">
            <p className="text-[11px] text-[#999999] text-center font-medium leading-none">
              © 2026 Indica Aracati - Direitos reservados para Valdriano Cruz
            </p>
          </div>
        </footer>

        {/* --- HIGH POLISHED SENSORY ALERTS SECTION --- */}

        {/* Warning Scam Dialog/Alert: 🛡️ Cuidado com Golpes */}
        {showScamWarning && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-40 animate-fade-in">
            <div className="bg-white rounded-xl max-w-sm w-[92%] p-5 shadow-2xl border-t-4 border-[#FF6B00] transform transition-transform animate-scale-up">
              <div className="flex items-center gap-2.5 mb-3">
                <div className="bg-orange-100 p-2 rounded-full text-[#FF6B00] shrink-0">
                  <ShieldAlert className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="text-[16px] font-bold text-gray-900 leading-tight">
                    CUIDADO COM GOLPES!
                  </h3>
                  <p className="text-[11px] text-orange-600 font-bold uppercase tracking-wider">
                    Segurança ao contratar em Aracati
                  </p>
                </div>
              </div>

              {/* Alert list formatted clearly for elderly readability */}
              <div className="space-y-2.5 my-3 bg-orange-50/50 p-3 rounded-lg border border-orange-100 text-gray-850 text-[13px]">
                <div className="flex items-start gap-1.5">
                  <span className="font-extrabold text-[#FF6B00]">1.</span>
                  <p className="font-medium leading-tight">Nunca faça pagamento adiantado.</p>
                </div>
                <div className="flex items-start gap-1.5">
                  <span className="font-extrabold text-[#FF6B00]">2.</span>
                  <p className="font-medium leading-tight">Desconfie de preços muito baixos.</p>
                </div>
                <div className="flex items-start gap-1.5">
                  <span className="font-extrabold text-[#FF6B00]">3.</span>
                  <p className="font-medium leading-tight">Peça referências do profissional.</p>
                </div>
                <div className="flex items-start gap-1.5">
                  <span className="font-extrabold text-[#FF6B00]">4.</span>
                  <p className="font-medium leading-tight">Combine o serviço pessoalmente.</p>
                </div>
                <div className="flex items-start gap-1.5">
                  <span className="font-extrabold text-[#FF6B00]">5.</span>
                  <p className="font-medium leading-tight">Em caso de golpe, denuncie pelo botão ⚠️.</p>
                </div>
              </div>

              <p className="text-[10px] text-gray-500 italic text-center font-medium bg-gray-50 p-2.5 rounded border border-gray-100">
                "O Indica Aracati não se responsabiliza por negociações entre usuários."
              </p>

              <button
                _id="btn-close-warning"
                onClick={() => setShowScamWarning(false)}
                className="w-full mt-4 py-3 bg-[#FF6B00] hover:bg-orange-600 text-white font-bold text-[13px] rounded-lg shadow-sm transition-colors cursor-pointer flex items-center justify-center gap-1.5"
              >
                <Check className="w-4 h-4" />
                <span>ENTENDI, MUITO OBRIGADO!</span>
              </button>
            </div>
          </div>
        )}

        {/* Modal: Confirm Denunciation options popup as specified */}
        {denouncingProfessional && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-40 animate-fade-in">
            <div className="bg-white rounded-xl max-w-sm w-[92%] p-5 shadow-2xl border-t-4 border-red-600 animate-scale-up">
              
              <div className="flex justify-between items-start mb-3">
                <div className="flex items-center gap-2 text-red-700">
                  <AlertTriangle className="w-5 h-5 shrink-0" />
                  <h3 className="text-[15px] font-bold tracking-tight">
                    Prevenir Abusos / Denunciar
                  </h3>
                </div>
                <button
                  onClick={() => setDenouncingProfessional(null)}
                  className="p-1 rounded-full hover:bg-gray-100 transition-colors"
                >
                  <X className="w-4 h-4 text-gray-400" />
                </button>
              </div>

              {!denounceReason ? (
                <>
                  <p className="text-[12px] text-gray-500 font-semibold mb-3 bg-red-50 p-2 rounded border border-red-100 leading-normal">
                    Você selecionou denunciar o profissional <strong className="text-red-700">{denouncingProfessional.name}</strong>. Por favor, selecione o motivo correspondente:
                  </p>

                  {/* Selection options: "Golpe ou fraude", "Cobrança elevada/abusiva", "Serviço mal feito", "Outro motivo" */}
                  <div className="space-y-1.5 text-left">
                    {(['Golpe ou fraude', 'Cobrança elevada/abusiva', 'Serviço mal feito', 'Outro motivo'] as DenounceReason[]).map((reason) => (
                      <button
                        key={reason}
                        onClick={() => handleSelectDenounceReason(reason)}
                        className="w-full px-3 py-2.5 text-left bg-gray-50 hover:bg-red-50 border border-gray-200 hover:border-red-300 rounded text-[13px] font-bold text-gray-850 transition-all flex justify-between items-center group cursor-pointer"
                      >
                        <span>⚠️ {reason}</span>
                        <ChevronRight className="w-3.5 h-3.5 text-gray-400 group-hover:text-red-500 transition-colors shrink-0" />
                      </button>
                    ))}
                  </div>

                  <button
                    onClick={() => setDenouncingProfessional(null)}
                    className="w-full mt-3.5 py-2 border border-gray-250 text-gray-650 bg-white hover:bg-gray-100 text-[12.5px] font-bold rounded-lg transition-colors cursor-pointer"
                  >
                    Voltar / Cancelar
                  </button>
                </>
              ) : (
                <form onSubmit={handleConfirmDenounce} className="space-y-3">
                  <p className="text-[12px] text-gray-500 font-medium">
                    Motivo selecionado: <strong className="text-red-700 text-[12.5px]">⚠️ {denounceReason}</strong>
                  </p>

                  {denounceError && (
                    <p className="text-[12px] text-red-600 font-bold bg-red-50 p-2 rounded border border-red-150">
                      {denounceError}
                    </p>
                  )}

                  <div className="space-y-1">
                    <label className="block text-[12px] font-bold text-gray-750">
                      Seu WhatsApp com DDD *
                    </label>
                    <input
                      type="tel"
                      value={denounceContact}
                      onChange={(e) => setDenounceContact(e.target.value)}
                      placeholder="Ex: 88999999999"
                      className="w-full border border-gray-300 rounded px-2.5 py-1.5 text-[13px] text-gray-800 outline-none focus:ring-1 focus:ring-red-500"
                    />
                  </div>

                  <div className="flex gap-2 pt-1">
                    <button
                      type="button"
                      onClick={() => setDenounceReason(null)}
                      className="w-[40%] py-2 border border-gray-300 text-gray-750 bg-white rounded text-[12.5px] font-semibold"
                    >
                      Alterar motivo
                    </button>
                    <button
                      type="submit"
                      className="w-[60%] py-2 bg-red-600 hover:bg-red-700 text-white rounded text-[12.5px] font-bold uppercase transition-colors"
                    >
                      Enviar Denúncia
                    </button>
                  </div>
                </form>
              )}
            </div>
          </div>
        )}

        {/* Modal: Denouncement success confirmation alert as specified */}
        {showDenounceSuccess && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-40 animate-fade-in">
            <div className="bg-white rounded-xl max-w-sm w-[90%] p-5 shadow-2xl border-t-4 border-red-600 text-center animate-scale-up">
              <div className="mx-auto w-12 h-12 bg-red-105 rounded-full flex items-center justify-center text-red-600 mb-3">
                <AlertTriangle className="w-6 h-6 animate-pulse" />
              </div>
              <h3 className="text-[17px] font-bold text-gray-900 mb-1.5">
                Denúncia Enviada!
              </h3>
              <p className="text-[13px] text-gray-650 mb-4 leading-relaxed font-semibold">
                Denúncia enviada. Obrigado por ajudar a manter o app seguro.
              </p>
              <button
                _id="btn-close-denounce-success"
                onClick={() => setShowDenounceSuccess(false)}
                className="w-full py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold text-[13.5px] rounded-lg transition-colors"
              >
                ENTENDI
              </button>
            </div>
          </div>
        )}

        {/* Modal: Interactive Rating / Review Selection 1 to 5 */}
        {ratingProfessional && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-40 animate-fade-in">
            <div className="bg-white rounded-xl max-w-sm w-[90%] p-5 shadow-2xl border-t-4 border-amber-500 text-center animate-scale-up">
              <div className="mx-auto w-12 h-12 bg-amber-50 rounded-full flex items-center justify-center text-amber-500 mb-3">
                <Star className="w-6 h-6 fill-current" />
              </div>
              <h3 className="text-[17px] font-bold text-gray-900 mb-1">
                Avaliar Profissional
              </h3>
              <p className="text-[13px] text-gray-650 mb-4 font-semibold">
                Sua avaliação espontânea para <span className="text-orange-700 font-extrabold">{ratingProfessional.name}</span>
              </p>
              
              {/* Star selector 1 to 5 */}
              <div className="flex justify-center gap-2 mb-5">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    type="button"
                    onClick={() => setChosenRating(star)}
                    className="cursor-pointer transition-transform active:scale-90 p-1"
                  >
                    <Star
                      className={`w-9 h-9 transition-all duration-150 ${
                        star <= chosenRating
                          ? 'text-amber-500 fill-amber-500'
                          : 'text-gray-300'
                      }`}
                    />
                  </button>
                ))}
              </div>

              <div className="p-2.5 bg-slate-50 border border-slate-100 rounded-lg text-xs text-gray-550 mb-5 leading-normal font-medium">
                Nota escolhida: <strong className="text-slate-900 text-sm font-bold">{chosenRating}</strong> de 5 estrelas
              </div>

              {/* Action buttons */}
              <div className="flex gap-2">
                <button
                  onClick={() => setRatingProfessional(null)}
                  className="w-[40%] py-2.5 border border-gray-300 text-gray-700 bg-white hover:bg-gray-50 rounded-lg text-[13px] font-bold transition-all cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  onClick={handleConfirmRating}
                  className="w-[60%] py-2.5 bg-amber-500 hover:bg-amber-600 active:scale-95 text-white font-bold text-[13px] rounded-lg shadow-md transition-all uppercase cursor-pointer"
                >
                  Confirmar
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Modal: Registration success confirmation alert as specified */}
        {showSuccessModal && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-40 animate-fade-in">
            <div className="bg-white rounded-xl max-w-sm w-[90%] p-5 shadow-2xl border-t-4 border-green-500 text-center animate-scale-up">
              <div className="mx-auto w-12 h-12 bg-green-100 rounded-full flex items-center justify-center text-green-600 mb-3">
                <Check className="w-6 h-6" />
              </div>
              <h3 className="text-[17px] font-bold text-gray-900 mb-1.5">
                Cadastro Realizado!
              </h3>
              <p className="text-[13px] text-gray-650 mb-4 leading-relaxed font-semibold">
                Cadastro realizado! Seu perfil já está ativo.
              </p>
              <button
                onClick={() => setShowSuccessModal(false)}
                className="w-full py-2.5 bg-[#4CAF50] hover:bg-green-600 text-white font-bold text-[13.5px] rounded-lg transition-colors"
              >
                FECHAR E VER MEU PERFIL
              </button>
            </div>
          </div>
        )}



        {/* Simple transient overlay toast messages */}
        {toastMessage && (
          <div className="absolute top-14 left-4 right-4 bg-gray-900/95 text-white p-3 rounded-lg shadow-lg flex items-center gap-2.5 z-50 animate-bounce-in max-w-xs mx-auto border border-gray-800">
            <Check className="w-4 h-4 text-green-400 shrink-0" />
            <p className="text-[12px] font-bold leading-normal flex-1">
              {toastMessage}
            </p>
          </div>
        )}

      </div>
    </div>
  );
}

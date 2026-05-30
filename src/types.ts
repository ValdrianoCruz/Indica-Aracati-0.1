export interface Professional {
  id: string;
  name: string;
  occupation: string;
  rating: number;
  reviewsCount: number;
  location: string;
  whatsappUrl: string;
  whatsappNumber: string;
  isNew?: boolean;
  registrationCode?: string;
}

export type DenounceReason =
  | 'Golpe ou fraude'
  | 'Cobrança elevada/abusiva'
  | 'Serviço mal feito'
  | 'Outro motivo';

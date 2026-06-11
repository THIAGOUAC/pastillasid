# <div align="center">

# 

# \# 💊 PastillasPE

# 

# \### Tu asistente inteligente de medicamentos

# 

# !\[Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)

# !\[Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge\&logo=firebase\&logoColor=black)

# !\[Gemini AI](https://img.shields.io/badge/Gemini\_AI-8E75B2?style=for-the-badge\&logo=google\&logoColor=white)

# !\[Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge\&logo=dart\&logoColor=white)

# 

# > Proyecto académico — Universidad Andina del Cusco  

# > Facultad de Ingeniería y Arquitectura  

# > Organización y Arquitectura del Computador — 2025-I

# 

# </div>

# 

# \---

# 

# \## 📱 ¿Qué es PastillasPE?

# 

# PastillasPE es una aplicación móvil desarrollada en Flutter para ayudar a los pacientes peruanos a gestionar sus tratamientos médicos de forma inteligente. Combina recordatorios, inteligencia artificial y una interfaz limpia con identidad visual médica peruana.

# 

# \---

# 

# \## ✨ Funcionalidades

# 

# \### 🔐 Autenticación

# \- Inicio de sesión con Google

# \- Autenticación biométrica (huella dactilar / Face ID)

# \- Sesión persistente con Firebase Auth

# 

# \### 💊 Gestión de Medicamentos

# \- Registro manual de medicamentos con dosis, horarios y stock

# \- Edición y eliminación de tratamientos

# \- Control de stock con alertas de reabastecimiento

# \- Activar / desactivar tratamientos

# 

# \### 🤖 Escáner IA con Gemini

# \- Toma una foto de tu receta médica, caja o frasco

# \- La IA extrae automáticamente nombre, dosis, horarios e indicaciones

# \- Muestra los datos parseados en una card limpia con badge de confianza

# \- El usuario confirma o edita antes de guardar

# 

# \### 🔔 Recordatorios Inteligentes

# \- Notificaciones diarias programadas por medicamento y horario

# \- Acciones rápidas: "Ya tomé" y "Lo tomaré en 10 min"

# \- Ventana emergente in-app al momento de la toma

# \- Reprogramación automática (snooze) de recordatorios

# 

# \### 📅 Calendario de Tomas

# \- Resumen diario con barra de progreso

# \- Vista semanal con strip de días

# \- Historial de tomas realizadas

# \- Proyección mensual de tratamientos

# 

# \### 💬 Dr. Gerbacio (Chatbot IA)

# \- Asistente virtual especializado en medicamentos peruanos

# \- Responde preguntas sobre dosis, interacciones y efectos secundarios

# \- Puede registrar medicamentos mediante conversación

# \- Accesible desde cualquier pantalla mediante botón flotante

# 

# \### 🏥 Farmacias Cercanas

# \- Detecta tu ubicación GPS

# \- Abre Google Maps centrado en farmacias cercanas

# \- Opción de obtener ruta de navegación

# 

# \---

# 

# \## 🛠️ Stack Tecnológico

# 

# | Categoría | Tecnología |

# |-----------|-----------|

# | Framework | Flutter + Dart |

# | Estado | Riverpod (StateNotifier) |

# | Navegación | GoRouter |

# | Backend | Firebase (Auth + Firestore) |

# | IA | Firebase AI / Gemini 2.5 Flash |

# | Notificaciones | flutter\_local\_notifications |

# | Biometría | local\_auth |

# | Mapas | Google Maps + Geolocator |

# | Arquitectura | Clean Architecture (Domain → Data → Presentation) |

# | DI | GetIt |

# 

# \---

# 

# \## 🏗️ Arquitectura



lib/

├── core/

│   ├── constants/        # Paleta de colores

│   ├── notifications/    # Servicio de notificaciones

│   ├── router/           # GoRouter + NavigatorKey

│   ├── theme/            # Tema claro/oscuro

│   └── widgets/          # Widgets reutilizables

└── features/

├── auth/             # Login + Biometría

├── calendar/         # Calendario de tomas

├── chatbot/          # Dr. Gerbacio (Gemini)

├── dashboard/        # Home + Shell

├── medications/      # CRUD medicamentos

├── medicine\_scan/    # Escáner IA

├── pharmacies/       # Farmacias cercanas

├── profile/          # Onboarding + perfil

├── reminders/        # Registro de tomas

├── settings/         # Configuración

└── splash/           # Splash animado





\---



\## 🎨 Paleta de Colores



| Rol | Color | Hex |

|-----|-------|-----|

| Azul médico (primary) | !\[#1A6B8A](https://placehold.co/15x15/1A6B8A/1A6B8A.png) | `#1A6B8A` |

| Verde salud (secondary) | !\[#2E8B57](https://placehold.co/15x15/2E8B57/2E8B57.png) | `#2E8B57` |

| Dorado peruano (accent) | !\[#C9952A](https://placehold.co/15x15/C9952A/C9952A.png) | `#C9952A` |

| Blanco clínico (bg) | !\[#F5F9FC](https://placehold.co/15x15/F5F9FC/F5F9FC.png) | `#F5F9FC` |

| Texto principal | !\[#1C2B3A](https://placehold.co/15x15/1C2B3A/1C2B3A.png) | `#1C2B3A` |



\---



\## 🚀 Instalación



\### Requisitos

\- Flutter SDK `^3.12.1`

\- Dart SDK `^3.12.1`

\- Android Studio o VS Code

\- Cuenta Firebase configurada



\### Pasos



```bash

\# 1. Clonar el repositorio

git clone https://github.com/THIAGOUAC/pastillasid.git

cd pastillasid



\# 2. Instalar dependencias

flutter pub get



\# 3. Configurar Firebase

\# Agrega tu google-services.json en android/app/

\# Agrega tu GoogleService-Info.plist en ios/Runner/



\# 4. Correr la app

flutter run

```



\---



\## 👥 Equipo



Desarrollado por el equipo de la sección A — Organización y Arquitectura del Computador 2025-I, Universidad Andina del Cusco.



\---



\## 📄 Licencia



Proyecto académico — Universidad Andina del Cusco © 2025



<div align="center">

Hecho con ❤️ en Cusco, Perú 🇵🇪

</div>


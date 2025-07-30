# Light of the Kalabhra

A 3D browser-based educational game exploring the ancient sanctuary of Kalabhra, built with Godot 4.x.

## Project Structure

### Scenes (`/scenes/`)
- **main/**: Main menu, loading screens, and core game scenes
- **characters/**: Player character and NPC scenes
  - `player/`: Player character controller and related scenes
  - `npcs/`: Non-player character scenes and behaviors
- **environments/**: Game world environments
  - `sanctuary/`: Main sanctuary areas
  - `chambers/`: Individual chamber scenes
  - `outdoor/`: Outdoor environment scenes
- **ui/**: User interface scenes
  - `menus/`: Game menus (main, pause, settings)
  - `hud/`: Heads-up display elements
  - `dialogs/`: Dialog and interaction UI
- **systems/**: Game system scenes
  - `tutorials/`: Tutorial and onboarding scenes
  - `assessments/`: Educational assessment interfaces
  - `inventory/`: Inventory and item management

### Scripts (`/scripts/`)
- **core/**: Core game systems and managers
- **characters/**: Character-related scripts
- **environments/**: Environment and world scripts
- **ui/**: User interface scripts
- **systems/**: Game system scripts
- **utils/**: Utility and helper scripts

### Assets (`/assets/`)
- **models/**: 3D models and meshes
  - `characters/`: Character models and animations
  - `environments/`: Environment and architectural models
  - `props/`: Interactive objects and props
- **textures/**: Texture files
  - `characters/`: Character textures and materials
  - `environments/`: Environment textures
  - `ui/`: UI textures and icons
  - `effects/`: Particle and effect textures
- **audio/**: Audio files
  - `music/`: Background music and ambient sounds
  - `sfx/`: Sound effects
  - `voice/`: Voice acting and narration
- **ui/**: UI-specific assets
  - `icons/`: Game icons and symbols
  - `splash/`: Splash screens and logos
  - `backgrounds/`: UI backgrounds
- **fonts/**: Font files for UI and text

### Resources (`/resources/`)
- **data/**: Game data and configuration
  - `educational/`: Educational content and curriculum data
  - `progress/`: Player progress tracking data
  - `config/`: Configuration files and settings
- **materials/**: Godot material resources
- **shaders/**: Custom shader files

### Localization (`/localization/`)
- Translation files for multi-language support
- CSV files for easy translation management

### Export Presets (`/export_presets/`)
- Platform-specific export configurations
- HTML5/WebGL export settings

## Core Systems

### Autoloaded Singletons
- **GameManager**: Main game state and flow control
- **ResourceManager**: Asset loading and memory management
- **SceneManager**: Scene transitions and loading
- **ConfigManager**: Settings and configuration management
- **InputManager**: Unified input handling for all platforms
- **SaveManager**: Save/load system for progress and data
- **LocalizationManager**: Multi-language support
- **AudioManager**: Audio playback and management

## Browser Compatibility

This project is optimized for browser deployment with:
- WebGL compatibility mode
- Touch input support for mobile devices
- Efficient asset loading for web constraints
- Progressive loading for large environments
- Browser-compatible save system using localStorage

## Development Guidelines

1. **Performance**: Always consider browser limitations and optimize for web deployment
2. **Accessibility**: Ensure compatibility with various input methods and screen sizes
3. **Modularity**: Keep systems decoupled and use the singleton managers for communication
4. **Localization**: Use the LocalizationManager for all user-facing text
5. **Asset Management**: Use the ResourceManager for all asset loading operations

## Getting Started

1. Open the project in Godot 4.x
2. Ensure HTML5 export template is installed
3. Configure export settings for your target deployment
4. Test in browser using the built-in web server

## Educational Framework

The game is designed to support educational content through:
- Modular lesson integration
- Progress tracking and assessment
- Adaptive difficulty based on performance
- Multi-modal learning approaches (visual, auditory, kinesthetic)

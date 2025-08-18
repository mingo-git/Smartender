// lib/models/websocket/websocket_message.dart

enum WebSocketMessageType {
  drinkUpdate('drink_update'),
  recipeUpdate('recipe_update'),
  slotUpdate('slot_update'),
  favoriteUpdate('favorite_update'),
  ingredientUpdate('ingredient_update'),
  unknown('unknown');

  const WebSocketMessageType(this.value);
  final String value;

  static WebSocketMessageType fromString(String value) {
    switch (value) {
      case 'drink_update':
        return WebSocketMessageType.drinkUpdate;
      case 'recipe_update':
        return WebSocketMessageType.recipeUpdate;
      case 'slot_update':
        return WebSocketMessageType.slotUpdate;
      case 'favorite_update':
        return WebSocketMessageType.favoriteUpdate;
      case 'ingredient_update':
        return WebSocketMessageType.ingredientUpdate;
      default:
        return WebSocketMessageType.unknown;
    }
  }
}

enum WebSocketAction {
  created('created'),
  updated('updated'),
  deleted('deleted'),
  unknown('unknown');

  const WebSocketAction(this.value);
  final String value;

  static WebSocketAction fromString(String value) {
    switch (value) {
      case 'created':
        return WebSocketAction.created;
      case 'updated':
        return WebSocketAction.updated;
      case 'deleted':
        return WebSocketAction.deleted;
      default:
        return WebSocketAction.unknown;
    }
  }
}

/// Base WebSocket Message
class WebSocketMessage {
  final WebSocketMessageType type;
  final Map<String, dynamic> data;

  WebSocketMessage({
    required this.type,
    required this.data,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: WebSocketMessageType.fromString(json['type'] ?? ''),
      data: json['data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'data': data,
    };
  }
}

/// Drink Update Message
class DrinkUpdateMessage {
  final WebSocketAction action;
  final Map<String, dynamic>? drink;

  DrinkUpdateMessage({
    required this.action,
    this.drink,
  });

  factory DrinkUpdateMessage.fromJson(Map<String, dynamic> json) {
    return DrinkUpdateMessage(
      action: WebSocketAction.fromString(json['action'] ?? ''),
      drink: json['drink'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.value,
      if (drink != null) 'drink': drink,
    };
  }
}

/// Recipe Update Message
class RecipeUpdateMessage {
  final WebSocketAction action;
  final Map<String, dynamic>? recipe;

  RecipeUpdateMessage({
    required this.action,
    this.recipe,
  });

  factory RecipeUpdateMessage.fromJson(Map<String, dynamic> json) {
    return RecipeUpdateMessage(
      action: WebSocketAction.fromString(json['action'] ?? ''),
      recipe: json['recipe'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.value,
      if (recipe != null) 'recipe': recipe,
    };
  }
}

/// Slot Update Message
class SlotUpdateMessage {
  final WebSocketAction action;
  final Map<String, dynamic>? slot;

  SlotUpdateMessage({
    required this.action,
    this.slot,
  });

  factory SlotUpdateMessage.fromJson(Map<String, dynamic> json) {
    return SlotUpdateMessage(
      action: WebSocketAction.fromString(json['action'] ?? ''),
      slot: json['slot'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.value,
      if (slot != null) 'slot': slot,
    };
  }
}

/// Favorite Update Message
class FavoriteUpdateMessage {
  final WebSocketAction action;
  final Map<String, dynamic>? favorite;
  final int? recipeId;

  FavoriteUpdateMessage({
    required this.action,
    this.favorite,
    this.recipeId,
  });

  factory FavoriteUpdateMessage.fromJson(Map<String, dynamic> json) {
    return FavoriteUpdateMessage(
      action: WebSocketAction.fromString(json['action'] ?? ''),
      favorite: json['favorite'] as Map<String, dynamic>?,
      recipeId: json['recipe_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.value,
      if (favorite != null) 'favorite': favorite,
      if (recipeId != null) 'recipe_id': recipeId,
    };
  }
}

/// Ingredient Update Message (for Recipe Ingredients)
class IngredientUpdateMessage {
  final WebSocketAction action;
  final Map<String, dynamic>? ingredient;
  final int? recipeId;

  IngredientUpdateMessage({
    required this.action,
    this.ingredient,
    this.recipeId,
  });

  factory IngredientUpdateMessage.fromJson(Map<String, dynamic> json) {
    return IngredientUpdateMessage(
      action: WebSocketAction.fromString(json['action'] ?? ''),
      ingredient: json['ingredient'] as Map<String, dynamic>?,
      recipeId: json['recipe_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.value,
      if (ingredient != null) 'ingredient': ingredient,
      if (recipeId != null) 'recipe_id': recipeId,
    };
  }
}

/// WebSocket Connection Status
enum WebSocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket Status Info
class WebSocketStatusInfo {
  final WebSocketConnectionStatus status;
  final String? errorMessage;
  final DateTime lastConnected;
  final int reconnectAttempts;

  WebSocketStatusInfo({
    required this.status,
    this.errorMessage,
    required this.lastConnected,
    this.reconnectAttempts = 0,
  });

  WebSocketStatusInfo copyWith({
    WebSocketConnectionStatus? status,
    String? errorMessage,
    DateTime? lastConnected,
    int? reconnectAttempts,
  }) {
    return WebSocketStatusInfo(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastConnected: lastConnected ?? this.lastConnected,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}

/// WebSocket Configuration
class WebSocketConfig {
  final String baseUrl;
  final String wsPath;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;
  final Duration pingInterval;
  final Duration connectionTimeout;

  const WebSocketConfig({
    required this.baseUrl,
    this.wsPath = '/api/ws',
    this.reconnectDelay = const Duration(seconds: 5),
    this.maxReconnectAttempts = 10,
    this.pingInterval = const Duration(seconds: 30),
    this.connectionTimeout = const Duration(seconds: 10),
  });

  String get wsUrl => baseUrl.replaceFirst('http', 'ws') + wsPath;
}
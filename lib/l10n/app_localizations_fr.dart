// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navShop => 'Boutique';

  @override
  String get navOrders => 'Commandes';

  @override
  String get navBookings => 'Réservations';

  @override
  String get navAccount => 'Compte';

  @override
  String get navViewCart => 'Voir le panier';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authSignOut => 'Se déconnecter';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authWelcomeBack => 'Bon retour';

  @override
  String get authSignInToContinue => 'Connectez-vous pour continuer';

  @override
  String get authDontHaveAccount => 'Pas de compte ?';

  @override
  String get authAlreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get authContinueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String authJoinStore(String storeName) {
    return 'Rejoignez $storeName aujourd\'hui';
  }

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authFullNameLabel => 'Nom complet';

  @override
  String get authPhoneLabel => 'Téléphone (facultatif)';

  @override
  String get authEmailRequired => 'L\'e-mail est requis';

  @override
  String get authEmailInvalid => 'Entrez un e-mail valide';

  @override
  String get authPasswordRequired => 'Le mot de passe est requis';

  @override
  String get authPasswordTooShort =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get authIncorrectCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String get authAccountNotFound => 'Aucun compte trouvé avec cet e-mail.';

  @override
  String get authEmailTaken => 'Un compte avec cet e-mail existe déjà.';

  @override
  String get authLoginFailed => 'Échec de la connexion. Veuillez réessayer.';

  @override
  String get authRegisterFailed =>
      'Échec de l\'inscription. Veuillez réessayer.';

  @override
  String catalogSearchHint(String storeName) {
    return 'Rechercher $storeName…';
  }

  @override
  String get catalogAll => 'Tout';

  @override
  String get catalogNoProducts => 'Aucun produit trouvé';

  @override
  String get catalogOutOfStock => 'Épuisé';

  @override
  String get catalogFailedToLoad => 'Échec du chargement des produits';

  @override
  String get productSpecialInstructions => 'Instructions spéciales';

  @override
  String get productInstructionsHint =>
      'Ex. sans oignons, sauce supplémentaire…';

  @override
  String get productRequired => 'Obligatoire';

  @override
  String productChooseUpTo(int max) {
    return 'Choisir jusqu\'à $max';
  }

  @override
  String productAddPrice(String price) {
    return 'Ajouter $price';
  }

  @override
  String productAddedToCart(String name) {
    return '$name ajouté au panier';
  }

  @override
  String get cartTitle => 'Votre panier';

  @override
  String get cartEmpty => 'Votre panier est vide';

  @override
  String get cartEmptyHint => 'Ajoutez des articles du menu pour commencer';

  @override
  String get cartBrowseMenu => 'Parcourir le menu';

  @override
  String get cartClearTitle => 'Vider le panier ?';

  @override
  String get cartClearMessage => 'Tous les articles seront supprimés.';

  @override
  String get cartClear => 'Vider';

  @override
  String get cartDiscountCode => 'Code de réduction';

  @override
  String get cartApply => 'Appliquer';

  @override
  String get cartSubtotal => 'Sous-total';

  @override
  String get cartDiscount => 'Réduction';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartProceedToCheckout => 'Passer à la caisse';

  @override
  String get checkoutTitle => 'Paiement';

  @override
  String get checkoutOrderType => 'Type de commande';

  @override
  String get checkoutPaymentMethod => 'Mode de paiement';

  @override
  String get checkoutNotes => 'Notes';

  @override
  String get checkoutNotesHint => 'Des instructions particulières ?';

  @override
  String get checkoutOrderSummary => 'Récapitulatif de la commande';

  @override
  String checkoutPlaceOrder(String total) {
    return 'Passer la commande — $total';
  }

  @override
  String get checkoutDeliveryAddress => 'Adresse de livraison';

  @override
  String get checkoutStreetAddress => 'Adresse';

  @override
  String get checkoutApartment => 'Appartement / Étage (facultatif)';

  @override
  String get checkoutCity => 'Ville';

  @override
  String get checkoutStreetRequired => 'L\'adresse est requise';

  @override
  String get checkoutCityRequired => 'La ville est requise';

  @override
  String get checkoutSelectTable => 'Sélectionnez votre table';

  @override
  String checkoutTableLabel(String name) {
    return 'Table $name';
  }

  @override
  String get checkoutAvailable => 'Disponible';

  @override
  String get checkoutOccupied => 'Occupée';

  @override
  String get checkoutSchedule => 'Planifier pour plus tard';

  @override
  String get checkoutScheduleTime => 'Heure de retrait';

  @override
  String checkoutLoyaltyAvailable(int points, String value) {
    return '$points pts disponibles (économisez $value)';
  }

  @override
  String get checkoutApplyPoints => 'Appliquer';

  @override
  String get checkoutRemovePoints => 'Retirer';

  @override
  String checkoutPointsApplied(int points) {
    return '$points pts appliqués';
  }

  @override
  String get checkoutOrderFailed => 'Échec de la commande. Veuillez réessayer.';

  @override
  String get checkoutNetworkError => 'Erreur réseau. Veuillez réessayer.';

  @override
  String get checkoutItemUnavailable =>
      'Un ou plusieurs articles ne sont plus disponibles.';

  @override
  String get orderTypePickup => 'Retrait';

  @override
  String get orderTypeDelivery => 'Livraison';

  @override
  String get orderTypeDineIn => 'Sur place';

  @override
  String get orderTypeTakeaway => 'À emporter';

  @override
  String get paymentCash => 'Espèces';

  @override
  String get paymentCard => 'Carte';

  @override
  String get paymentGiftCard => 'Carte cadeau';

  @override
  String get statusPending => 'Commande passée';

  @override
  String get statusConfirmed => 'Confirmée';

  @override
  String get statusProcessing => 'En préparation';

  @override
  String get statusReady => 'Prête';

  @override
  String get statusCompleted => 'Terminée';

  @override
  String get statusCancelled => 'Annulée';

  @override
  String get ordersTitle => 'Mes commandes';

  @override
  String get ordersEmpty => 'Pas encore de commandes';

  @override
  String get ordersEmptyHint => 'Votre historique de commandes apparaîtra ici';

  @override
  String get ordersTrack => 'Suivre la commande';

  @override
  String get ordersSignInRequired => 'Connectez-vous pour voir vos commandes';

  @override
  String get ordersFailed => 'Échec du chargement des commandes';

  @override
  String get orderDetailTitle => 'Détails de la commande';

  @override
  String get orderDetailItems => 'Articles';

  @override
  String get orderDetailNotes => 'Notes';

  @override
  String get orderDetailCouldNotLoad => 'Impossible de charger la commande';

  @override
  String get trackingTitle => 'Suivi de commande';

  @override
  String get trackingYourOrder => 'Votre commande';

  @override
  String get trackingViewAll => 'Voir toutes les commandes';

  @override
  String get trackingContinueShopping => 'Continuer les achats';

  @override
  String get trackingCancelled => 'Cette commande a été annulée';

  @override
  String get accountTitle => 'Compte';

  @override
  String get accountLoyaltyPoints => 'Points de fidélité';

  @override
  String get accountStoreCredit => 'Crédit boutique';

  @override
  String get accountMyOrders => 'Mes commandes';

  @override
  String get accountDarkMode => 'Mode sombre';

  @override
  String get accountLanguage => 'Langue';

  @override
  String get accountPreferences => 'Préférences';

  @override
  String get accountSupport => 'Assistance';

  @override
  String get accountAbout => 'À propos';

  @override
  String get accountShopping => 'Achats';

  @override
  String get accountSignInRequired => 'Connectez-vous pour voir votre compte';

  @override
  String get accountSignInBenefit =>
      'Connectez-vous pour suivre les commandes, gagner des points de fidélité et plus encore';

  @override
  String get accountSignOutTitle => 'Se déconnecter ?';

  @override
  String get accountSignOutMessage =>
      'Vous devrez vous reconnecter pour passer des commandes.';

  @override
  String get apptTitle => 'Mes réservations';

  @override
  String get apptEmpty => 'Pas encore de réservations';

  @override
  String get apptEmptyHint => 'Appuyez sur + pour réserver un rendez-vous';

  @override
  String get apptBook => 'Réserver';

  @override
  String get apptBookTitle => 'Prendre un rendez-vous';

  @override
  String get apptConfirm => 'Confirmer la réservation';

  @override
  String get apptSignInRequired => 'Connectez-vous pour gérer les réservations';

  @override
  String get apptNotesHint => 'Remarques ou demandes…';

  @override
  String get apptBookingFailed =>
      'Échec de la réservation. Veuillez réessayer.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonError => 'Une erreur s\'est produite';

  @override
  String get commonNetworkError => 'Pas de connexion Internet';

  @override
  String get commonSignIn => 'Se connecter';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langSpanish => 'Español';

  @override
  String get splashInvalidKeyTitle => 'Clé API invalide';

  @override
  String get splashInvalidKeyMessage =>
      'La clé API configurée pour cette application est invalide ou révoquée.';

  @override
  String get splashInvalidKeyHint =>
      'Contactez le propriétaire de l\'application pour mettre à jour la clé.';

  @override
  String get splashNoSubscriptionTitle => 'Aucun abonnement actif';

  @override
  String get splashNoSubscriptionMessage =>
      'Ce compte n\'a pas d\'abonnement POS actif.';

  @override
  String get splashNoSubscriptionLink => 'S\'abonner sur xeboki.com/xe-pos →';

  @override
  String get splashNoSubscriptionHint =>
      'L\'application sera disponible une fois l\'abonnement activé.';

  @override
  String get splashFreePlanTitle => 'Mise à niveau requise';

  @override
  String get splashFreePlanMessage =>
      'L\'application de commande n\'est pas disponible avec le plan POS gratuit.';

  @override
  String get splashFreePlanLink => 'Mettre à niveau sur xeboki.com/xe-pos →';

  @override
  String get splashFreePlanHint =>
      'Le plan gratuit inclut uniquement le POS en magasin. La commande en ligne nécessite un plan payant.';

  @override
  String get splashFeatureNotInPlanTitle => 'Fonctionnalité non incluse';

  @override
  String get splashFeatureNotInPlanMessage =>
      'Votre plan POS actuel n\'inclut pas l\'application de commande.';

  @override
  String get splashFeatureNotInPlanLink =>
      'Mettre à niveau sur xeboki.com/xe-pos →';

  @override
  String get splashFeatureNotInPlanHint =>
      'Visitez xeboki.com/xe-pos pour mettre à niveau votre plan.';

  @override
  String get splashNetworkErrorTitle => 'Pas de connexion';

  @override
  String get splashNetworkErrorMessage =>
      'Impossible de vérifier votre abonnement. Vérifiez votre connexion internet et réessayez.';

  @override
  String get splashNetworkErrorHint =>
      'L\'application nécessite une connexion pour démarrer.';

  @override
  String get splashChecking => 'Vérification…';

  @override
  String get splashPoweredBy => 'Propulsé par';
}

from pathlib import Path
from django.core.management.utils import get_random_secret_key
from dotenv import load_dotenv
import hvac
import os
import constants


def get_vault_secrets(mount="DB"):
    """
    Получает секреты из Hashicorp Vault
    """
    try:
        client = hvac.Client(
            url=os.environ.get('VAULT_ADDR', 'http://vault:8201'),
            token=os.getenv('VAULT_TOKEN',"default-token")
        )

        if not client.is_authenticated():
            print("Vault client not authenticated, using fallback to env variables")
            return {}
        
        response = client.secrets.kv.read_secret_version(
            path=mount,
            mount_point='foodgram'
        )

        print("Successfully loaded secrets from Vault")
        return response['data']['data']

    except Exception as e:
        print(f"Warning: Could not fetch secrets from Vault: {e}")
        print("Using fallback to environment variables")
        return {}


def get_setting(key, mount, default=None):
    vault_secrets = get_vault_secrets(mount)
    return vault_secrets.get(key, os.getenv(key, default))


load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv("SECRET_KEY", get_random_secret_key())

# DEBUG = os.getenv("DEBUG", default=True)
DEBUG = get_setting("DEBUG", "DJANGO")

# ALLOWED_HOSTS = (
#     os.getenv("ALLOWED_HOSTS", default='127.0.0.1,localhost').split(",")
# )

ALLOWED_HOSTS = (
    get_setting("ALLOWED_HOSTS", "DJANGO").split(",")
)

CSRF_TRUSTED_ORIGINS = [
    'http://localhost',
    'http://127.0.0.1',
    'http://backend',
]

CORS_ALLOWED_ORIGINS = [
    'http://localhost',
    'http://127.0.0.1',
    'http://backend',
]

CORS_ALLOW_CREDENTIALS = True


INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'rest_framework_simplejwt',
    'recipes.apps.AppConfig',
    'api.apps.AppConfig',
    'djoser',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'foodgram.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'foodgram.wsgi.application'

# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.postgresql',
#         'NAME': os.getenv('POSTGRES_DB', 'postgres'),
#         'USER': os.getenv('POSTGRES_USER', 'postgres'),
#         'PASSWORD': os.getenv('POSTGRES_PASSWORD', 'postgres'),
#         'HOST': os.getenv('DB_HOST', '127.0.0.1'),
#         'PORT': os.getenv('DB_PORT', 5432)
#     }
# }

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': get_setting("POSTGRES_DB", "DB"),
        'USER': get_setting('POSTGRES_USER', 'DB'),
        'PASSWORD': get_setting('POSTGRES_PASSWORD', 'DB'),
        'HOST': get_setting('DB_HOST', 'DB'),
        'PORT': get_setting('DB_PORT', 'DB')
    }
}
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

LANGUAGE_CODE = 'ru-RU'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'static'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


AUTH_USER_MODEL = 'recipes.User'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
    'DEFAULT_PAGINATION_CLASS': 'api.pagination.PagesPagination',
    'PAGE_SIZE': constants.PAGE_SIZE,
}

DJOSER = {
    'SERIALIZERS': {
        'user': 'api.serializers.UserSerializer',
        'current_user': 'api.serializers.UserSerializer',
    },
    'PERMISSIONS': {
        'user': ['djoser.permissions.CurrentUserOrAdminOrReadOnly'],
        'user_list': ['rest_framework.permissions.IsAuthenticatedOrReadOnly'],
    },
    'HIDE_USERS': False,
    'USER_CREATE_PASSWORD_RETYPE': False,
    'SEND_ACTIVATION_EMAIL': False,
    'SET_PASSWORD_RETYPE': False,
    'PASSWORD_RESET_CONFIRM_RETYPE': False,
    'TOKEN_MODEL': 'rest_framework.authtoken.models.Token',
}

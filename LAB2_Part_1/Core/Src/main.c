/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <arm_math.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
/* ตัวแปร Global สำหรับ CubeMonitor */
float32_t V_in = 0.0f;
float32_t Wm_sim = 0.0f;
float32_t Wm_real = 0.0f;

/* ตัวแปร State สำหรับ Difference Equation */
float32_t V_in_n2 = 0.0f;
float32_t Wm_n1 = 0.0f;
float32_t Wm_n2 = 0.0f;

/* Parameters ของมอเตอร์ */
float32_t Rm = 1.0f;
float32_t Lm = 0.5f;
float32_t Bm = 0.1f;
float32_t J  = 0.05f;
float32_t Km = 0.01f;
float32_t Ke = 0.01f;

/* ตัวแปรระบบ */
float32_t dt = 0.01f;
float32_t t = 0.0f;
int input_type = 1;

/* ตัวแปรสำหรับ Encoder */
int32_t encoder_count = 0;
int32_t prev_encoder_count = 0;

/* ค่าคงที่สำหรับสมการ */
float32_t term1, term2, term3;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
void Init_Motor_Coefficients(void) {
    float32_t Lm_J = Lm * J;
    term1 = (Km * dt * dt) / Lm_J;

    float32_t term2_num = (Rm * Bm + Ke * Km) * (dt * dt) + (-Lm * Bm - Rm * J) * dt + Lm_J;
    term2 = term2_num / Lm_J;

    float32_t term3_num = (Lm * Bm + Rm * J) * dt - (2.0f * Lm_J);
    term3 = term3_num / Lm_J;
}
/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_TIM2_Init();
  MX_TIM3_Init();
  MX_TIM4_Init();
  MX_USART1_UART_Init();
  /* USER CODE BEGIN 2 */
  Init_Motor_Coefficients();

    HAL_TIM_Base_Start_IT(&htim2);
    HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);
    HAL_TIM_Encoder_Start(&htim4, TIM_CHANNEL_ALL);
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE1_BOOST);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = RCC_PLLM_DIV4;
  RCC_OscInitStruct.PLL.PLLN = 85;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = RCC_PLLQ_DIV2;
  RCC_OscInitStruct.PLL.PLLR = RCC_PLLR_DIV2;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_4) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
    if (htim->Instance == TIM2) {

        // 1. สร้างสัญญาณ Input
        if (input_type == 1) {
            V_in = 12.0f * arm_sin_f32(2.0f * PI * 1.0f * t);
        } else if (input_type == 2) {
            if (t >= 1.0f) {
                V_in = 1.0f * (t - 1.0f);
            } else {
                V_in = 0.0f;
            }
        }

        if (V_in > 12.0f) V_in = 12.0f;
        if (V_in < -12.0f) V_in = -12.0f;

        // 2. คำนวณ HIL Simulation
        Wm_sim = (term1 * V_in_n2) - (term2 * Wm_n2) - (term3 * Wm_n1);

        V_in_n2 = V_in;
        Wm_n2 = Wm_n1;
        Wm_n1 = Wm_sim;

        // 3. ควบคุมมอเตอร์จริง
        uint32_t ARR_Value = __HAL_TIM_GET_AUTORELOAD(&htim3);
        float32_t abs_V_in = (V_in < 0.0f) ? -V_in : V_in;
        uint32_t duty_cycle = (uint32_t)((abs_V_in / 12.0f) * (float32_t)ARR_Value);

        __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, duty_cycle);

        if (V_in >= 0.0f) {
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_6, GPIO_PIN_SET);
            HAL_GPIO_WritePin(GPIOA, GPIO_PIN_2, GPIO_PIN_RESET);
        } else {
            HAL_GPIO_WritePin(GPIOC, GPIO_PIN_6, GPIO_PIN_RESET);
            HAL_GPIO_WritePin(GPIOA, GPIO_PIN_2, GPIO_PIN_SET);
        }

        // 4. อ่านค่าความเร็วมอเตอร์จริง
        encoder_count = (int32_t)__HAL_TIM_GET_COUNTER(&htim4);
        int32_t delta_count = encoder_count - prev_encoder_count;

        if (delta_count > 32767) delta_count -= 65536;
        else if (delta_count < -32768) delta_count += 65536;

        float32_t PPR = 1000.0f; // เปลี่ยนค่าตามสเปค Encoder จริง
        Wm_real = ((float32_t)delta_count / PPR) * (2.0f * PI) / dt;

        prev_encoder_count = encoder_count;
        t += dt;
    }
}
/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}
#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

import java.util.Random;
import java.lang.Integer;

public class matrixMultiplication
{
  public static void main (String[] args)
  {
    int rows = 1080;
    int columns = 1920;
    int integer = Integer.parseInt(args[0]);
    
    int[][] matrixA = new int [rows][columns];
    int[][] matrixB = new int [columns][integer];
    int[][] resultMatrix = new int [rows][integer];

    Random rand_int = new Random();

    // filling matrix A
    for(int i = 1; i <= rows; i++)
    {
      for (int j = 1; j <= columns; j++)
      {
        matrixA[i][i] = rand_int.nextInt(256);
      }
    }
    // filling matrix B
    for(int i = 1; i <= columns; i++)
    {
      for(int j = 1; j <= integer; j++)
      {
        matrixB[i][j] = rand_int.nextInt(256);
      }
    }

    // preforming the mult of A and B
    for(int i = 1; i <= rows; i++)
    {
      for(int j = 1; j <= integer; j++)
      {
        for (int k = 1; k <= columns; k++)
        {
          resultMatrix[i][j] = (matrixA[i][k] * matrixB[k][j]) + resultMatrix[i][j];
        }
        System.out.println(resultMatrix[i][j]);
      }
    }
  }
}
